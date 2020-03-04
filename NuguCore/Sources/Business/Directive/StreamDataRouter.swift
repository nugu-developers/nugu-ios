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
    public weak var upstreamDataDelegate: UpstreamDataDelegate?
    
    private let delegates = DelegateSet<DownstreamDataDelegate>()
    private var preprocessors = [DownstreamDataPreprocessable]()
    private let downstreamDataTimeoutPreprocessor = DownstreamDataTimeoutPreprocessor()
    
    private let networkManager: NetworkManageable
    
    private let disposeBag = DisposeBag()
    private let directiveSubject = PublishSubject<Downstream.Directive>()
    
    public init(networkManager: NetworkManageable) {
        self.networkManager = networkManager
        networkManager.add(receiveMessageDelegate: self)
        
        add(preprocessor: downstreamDataTimeoutPreprocessor)
    }
    
    public func add(preprocessor: DownstreamDataPreprocessable) {
        preprocessors.append(preprocessor)
    }
    
    public func add(delegate: DownstreamDataDelegate) {
        delegates.add(delegate)
    }
    
    public func remove(delegate: DownstreamDataDelegate) {
        delegates.remove(delegate)
    }
}

// MARK: - ReceiveMessageDelegate

extension StreamDataRouter: ReceiveMessageDelegate {
    public func receiveMessageDidReceive(header: [String: String], body: Data) {
        if let contentType = header["Content-Type"], contentType.contains("application/json") {
            guard let bodyDictionary = try? JSONSerialization.jsonObject(with: body, options: []) as? [String: Any],
                let directiveArray = bodyDictionary["directives"] as? [[String: Any]] else {
                    log.error("Decode Message failed")
                return
            }
            let directivies = directiveArray
                .compactMap(Downstream.Directive.init)
                .compactMap(preprocess)
            
            directivies.forEach { directive in
                directiveSubject.onNext(directive)
                delegates.notify { delegate in
                    delegate.downstreamDataDidReceive(directive: directive)
                }
            }
        } else if let attachment = Downstream.Attachment(headerDictionary: header, body: body) {
            if let attachment = preprocess(message: attachment) {
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
    public func send(
        upstreamEventMessage: UpstreamEventMessage,
        completion: ((Result<Data, Error>) -> Void)?,
        resultHandler: ((Result<Downstream.Directive, Error>) -> Void)?
    ) {
        guard let apiProvider = networkManager.apiProvider else {
            let error = NetworkError.unavailable
            upstreamDataDelegate?.upstreamDataDidSend(upstreamEventMessage: upstreamEventMessage, result: .failure(error))
            // TODO: HTTP/2 전이중 방식으로 변경시 completion, resultHandler 통합
            completion?(.failure(error))
            resultHandler?(.failure(error))
            return
        }
        // body
        guard let bodyData = ("{ \"context\": \(upstreamEventMessage.contextString)"
            + ",\"event\": {"
            + "\"header\": \(upstreamEventMessage.headerString)"
            + ",\"payload\": \(upstreamEventMessage.payloadString) }"
            + " }").data(using: .utf8) else {
                let error = NetworkError.invalidParameter
                upstreamDataDelegate?.upstreamDataDidSend(upstreamEventMessage: upstreamEventMessage, result: .failure(error))
                // TODO: HTTP/2 전이중 방식으로 변경시 completion, resultHandler 통합
                completion?(.failure(error))
                resultHandler?(.failure(error))
                return
        }
        
        let request = NuguApiRequest(
            path: NuguApi.event.path,
            method: NuguApi.event.method.rawValue,
            header: NuguApi.event.header,
            bodyData: bodyData,
            queryItems: [:]
        )
        apiProvider.request(with: request) { [weak self] result in
            guard let self = self else { return }
            self.upstreamDataDelegate?.upstreamDataDidSend(upstreamEventMessage: upstreamEventMessage, result: result)
            // TODO: HTTP/2 전이중 방식으로 변경시 completion, resultHandler 통합
            completion?(result)
            switch result {
            case .success:
                if let resultHandler = resultHandler {
                    self.observeResultDirective(dialogRequestId: upstreamEventMessage.header.dialogRequestId, resultHandler: resultHandler)
                }
            case .failure(let error):
                resultHandler?(.failure(error))
            }
        }
    }
    
    public func send(
        upstreamAttachment: UpstreamAttachment,
        completion: ((Result<Data, Error>) -> Void)?,
        resultHandler: ((Result<Downstream.Directive, Error>) -> Void)?
    ) {
        guard let apiProvider = networkManager.apiProvider else {
            let error = NetworkError.unavailable
            upstreamDataDelegate?.upstreamDataDidSend(upstreamAttachment: upstreamAttachment, result: .failure(error))
            // TODO: HTTP/2 전이중 방식으로 변경시 completion, resultHandler 통합
            completion?(.failure(error))
            resultHandler?(.failure(error))
            return
        }
        
        let queryItems = [
            "User-Agent": NetworkConst.userAgent,
            "Content-Type": "application/octet-stream",
            "namespace": upstreamAttachment.header.namespace,
            "name": upstreamAttachment.header.name,
            "dialogRequestId": upstreamAttachment.header.dialogRequestId,
            "messageId": upstreamAttachment.header.messageId,
            "version": upstreamAttachment.header.version,
            "parentMessageId": upstreamAttachment.header.messageId,
            "seq": String(upstreamAttachment.seq),
            "isEnd": upstreamAttachment.isEnd ? "true" : "false"
        ]
        
        let request = NuguApiRequest(
            path: NuguApi.eventAttachment.path,
            method: NuguApi.eventAttachment.method.rawValue,
            header: NuguApi.eventAttachment.header,
            bodyData: upstreamAttachment.content,
            queryItems: queryItems
        )
        
        apiProvider.request(with: request) { [weak self] result in
            guard let self = self else { return }
            self.upstreamDataDelegate?.upstreamDataDidSend(upstreamAttachment: upstreamAttachment, result: result)
            // TODO: HTTP/2 전이중 방식으로 변경시 completion, resultHandler 통합
            completion?(result)
            switch result {
            case .success:
                if let resultHandler = resultHandler {
                    self.observeResultDirective(dialogRequestId: upstreamAttachment.header.dialogRequestId, resultHandler: resultHandler)
                }
            case .failure(let error):
                resultHandler?(.failure(error))
            }
        }
        apiProvider.request(with: request, completion: completion)
    }
    
    public func send(crashReports: [CrashReport]) {
        guard let apiProvider = networkManager.apiProvider else { return }
        guard let bodyData = try? JSONEncoder().encode(crashReports) else { return }
        
        let request = NuguApiRequest(
            path: NuguApi.crashReport.path,
            method: NuguApi.crashReport.method.rawValue,
            header: NuguApi.crashReport.header,
            bodyData: bodyData,
            queryItems: [:]
        )
        apiProvider.request(with: request, completion: nil)
    }
}

// MARK: - Private

extension StreamDataRouter {
    func preprocess<T>(message: T) -> T? where T: DownstreamMessageable {
        return preprocessors.reduce(message) { (result, preprocessor) -> T? in
            guard let result = result else { return nil}
            return preprocessor.preprocess(message: result)
        }
    }
    
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
