//
//  StreamDataRouter.swift
//  NuguCore
//
//  Created by MinChul Lee on 11/22/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

import RxSwift

public class StreamDataRouter: StreamDataRoutable {
    private let delegates = DelegateSet<DownstreamDataDelegate>()
    private let downstreamDataTimeoutPreprocessor = DownstreamDataTimeoutPreprocessor()

    private let disposeBag = DisposeBag()
    private let directiveSubject = PublishSubject<Downstream.Directive>()
    
    private var eventSenders = [String: EventSender]()
    private let nuguApiProvider = NuguApiProvider(options: .receiveServerSideEvent)!
    
    public init() {}
    
    public func add(delegate: DownstreamDataDelegate) {
        delegates.add(delegate)
    }
    
    public func remove(delegate: DownstreamDataDelegate) {
        delegates.remove(delegate)
    }
}

// MARK: - ReceiveMessageDelegate

extension StreamDataRouter: ReceiveMessageDelegate {
    // TODO: This is for server initiated directve only now. Change It!!
    public func receiveMessageDidReceive(header: [String: String], body: Data) {
        if let contentType = header["Content-Type"], contentType.contains("application/json") {
            guard let bodyDictionary = try? JSONSerialization.jsonObject(with: body, options: []) as? [String: Any],
                let directiveArray = bodyDictionary["directives"] as? [[String: Any]] else {
                    log.error("Decode Message failed")
                return
            }
            let directivies = directiveArray
                .compactMap(Downstream.Directive.init)
                .compactMap(downstreamDataTimeoutPreprocessor.preprocess)
            
            directivies.forEach { directive in
                directiveSubject.onNext(directive)
                delegates.notify { delegate in
                    delegate.downstreamDataDidReceive(directive: directive)
                }
            }
        } else if let attachment = Downstream.Attachment(headerDictionary: header, body: body) {
            if let attachment = downstreamDataTimeoutPreprocessor.preprocess(message: attachment) {
                delegates.notify { delegate in
                    delegate.downstreamDataDidReceive(attachment: attachment)
                }
            }
        } else {
            log.error("Invalid data \(header)")
        }
    }
}

// MARK: - UpstreamDataSendable

extension StreamDataRouter: UpstreamDataSendable {
    public func sendEvent(
        upstreamEventMessage: UpstreamEventMessage,
        completion: ((Result<Void, Error>) -> Void)?,
        resultHandler: ((Result<Downstream.Directive, Error>) -> Void)?
    ) {
        sendStream(upstreamEventMessage: upstreamEventMessage, completion: { [weak self] result in
            // close stream automatically.
            self?.eventSenders[upstreamEventMessage.header.dialogRequestId]?.finish()
            completion?(result)
        }, resultHandler: resultHandler)
    }
    
    public func sendStream(
        upstreamEventMessage: UpstreamEventMessage,
        completion: ((Result<Void, Error>) -> Void)?,
        resultHandler: ((Result<Downstream.Directive, Error>) -> Void)?
    ) {
        let eventSender = EventSender(nuguApiProvider: nuguApiProvider)
        eventSenders[upstreamEventMessage.header.dialogRequestId] = eventSender
        eventSender.send(upstreamEventMessage) { [weak self] result in
            switch result {
            case .failure(let error):
                defer {
                    self?.eventSenders[upstreamEventMessage.header.dialogRequestId] = nil
                }
                
                guard (error as? EventSenderError) != nil else {
                    // response error
                    resultHandler?(.failure(error))
                    return
                }
                
                // request error
                completion?(.failure(error))
                
            case .success(let response):
                switch response {
                case .sent:
                    completion?(.success(()))
                case .received(let part):
                    self?.makeDirective(with: part, resultHandler: resultHandler)
                case .finished:
                    self?.eventSenders[upstreamEventMessage.header.dialogRequestId] = nil
                }
            }
        }
    }
    
    public func sendStream(
        upstreamAttachment: UpstreamAttachment,
        completion: ((Result<Void, Error>) -> Void)?
    ) {
        guard let eventSender = eventSenders[upstreamAttachment.header.dialogRequestId] else {
            completion?(.failure(EventSenderError.noEventRequested))
            return
        }
        
        eventSender.send(upstreamAttachment, completeHandler: {
            if upstreamAttachment.isEnd {
                eventSender.finish()
            }

            completion?($0)
        })
    }
    
    private func makeDirective(with part: MultiPartParser.Part, resultHandler: ((Result<Downstream.Directive, Error>) -> Void)? = nil) {
        if let contentType = part.header["Content-Type"], contentType.contains("application/json") {
            guard let bodyDictionary = try? JSONSerialization.jsonObject(with: part.body, options: []) as? [String: Any],
                let directiveArray = bodyDictionary["directives"] as? [[String: Any]] else {
                    log.error("Decode Message failed")
                    resultHandler?(.failure(NetworkError.invalidMessageReceived))
                    return
            }

            directiveArray
                .compactMap(Downstream.Directive.init)
                .compactMap(self.downstreamDataTimeoutPreprocessor.preprocess)
                .forEach { directive in
                    directiveSubject.onNext(directive)
                    delegates.notify { delegate in
                        delegate.downstreamDataDidReceive(directive: directive)
                    }
                    
                    resultHandler?(.success(directive))
            }
        } else if let attachment = Downstream.Attachment(headerDictionary: part.header, body: part.body) {
            if let attachment = self.downstreamDataTimeoutPreprocessor.preprocess(message: attachment) {
                self.delegates.notify { delegate in
                    delegate.downstreamDataDidReceive(attachment: attachment)
                }
            }
        } else {
            log.error("Invalid data \(part.header)")
        }
    }
    
    public func send(crashReports: [CrashReport]) {
//        guard let apiProvider = networkManager.apiProvider else { return }
//        guard let bodyData = try? JSONEncoder().encode(crashReports) else { return }
//        
//        let request = NuguApiRequest(
//            path: NuguApi.crashReport.path,
//            method: NuguApi.crashReport.method.rawValue,
//            header: NuguApi.crashReport.header,
//            bodyData: bodyData,
//            queryItems: [:]
//        )
//        apiProvider.request(with: request, completion: nil)
    }
}

// MARK: - Private

private extension StreamDataRouter {
    func observeResultDirective(dialogRequestId: String, resultHandler: @escaping (Result<Downstream.Directive, Error>) -> Void) {
        directiveSubject
            .filter { $0.header.dialogRequestId == dialogRequestId }
            // Ignore ASR.NotifyResult directive to take result directive.
            // TODO: HTTP/2 전이중 방식으로 변경시 최종 개선
            .filter { $0.header.type != "ASR.NotifyResult" }
            .take(1)
            .timeout(NuguConfiguration.deviceGatewayResponseTimeout, scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
            .catchError({ [weak self] error -> Observable<Downstream.Directive> in
                guard case RxError.timeout = error else {
                    return Observable.error(error)
                }
                
                self?.downstreamDataTimeoutPreprocessor.appendTimeoutDialogRequestId(dialogRequestId)
                return Observable.error(NetworkError.timeout)
            })
            .do(onNext: { directive in
                resultHandler(.success(directive))
            }, onError: { error in
                resultHandler(.failure(error))
            })
            .subscribe().disposed(by: disposeBag)
    }
}

// MARK: - resource server

extension StreamDataRouter {
    public func handOffResourceServer(to serverPolicy: Policy.ServerPolicy) {
        // TODO: handoff
    }
}

// MARK: - Downstream.Attachment initializer

extension Downstream.Attachment {
    init?(headerDictionary: [String: String], body: Data) {
        guard let header = Downstream.Header(headerDictionary: headerDictionary),
            let fileInfo = headerDictionary["Filename"]?.split(separator: ";"),
            fileInfo.count == 2,
            let fileSequence = Int(String(fileInfo[0])),
            let mediaType = headerDictionary["Content-Type"],
            let parentMessageId = headerDictionary["Parent-Message-Id"] else {
                return nil
        }
        
        self.init(header: header, seq: fileSequence, content: body, isEnd: fileInfo[1] == "end", parentMessageId: parentMessageId, mediaType: mediaType)
    }
}

// MARK: - Downstream.Directive initializer

extension Downstream.Directive {
    init?(directiveDictionary: [String: Any]) {
        guard let headerDictionary = directiveDictionary["header"] as? [String: Any],
            let headerData = try? JSONSerialization.data(withJSONObject: headerDictionary, options: []),
            let header = try? JSONDecoder().decode(Downstream.Header.self, from: headerData),
            let payloadDictionary = directiveDictionary["payload"] as? [String: Any],
            let payloadData = try? JSONSerialization.data(withJSONObject: payloadDictionary, options: []),
            let payload = String(data: payloadData, encoding: .utf8) else {
                return nil
        }
        
        self.init(header: header, payload: payload)
    }
}

// MARK: - Downstream.Header initializer

extension Downstream.Header {
    init?(headerDictionary: [String: String]) {
        guard let namespace = headerDictionary["Namespace"],
            let name = headerDictionary["Name"],
            let dialogRequestId = headerDictionary["Dialog-Request-Id"],
            let version = headerDictionary["Version"] else {
                return nil
        }
        
        self.init(namespace: namespace, name: name, dialogRequestId: dialogRequestId, messageId: "", version: version)
    }
}
