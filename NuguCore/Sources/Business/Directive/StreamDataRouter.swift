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
    public weak var delegate: DownstreamDataDelegate?
    private let downstreamDataTimeoutPreprocessor = DownstreamDataTimeoutPreprocessor()
    
    private var eventSenders = [String: EventSender]()
    private let nuguApiProvider = NuguApiProvider()
    
    private var serverSideEventDisposable: Disposable?
    private let disposeBag = DisposeBag()
    
    public var chargingFreeUrl: String = "" {
        didSet {
            log.debug("charging free url: \(chargingFreeUrl)")
            NuguServerInfo.registryAddress = chargingFreeUrl
            NuguServerInfo.resourceServerAddress = nil
            nuguApiProvider.isChargingFree = true
        }
    }
    
    public init() {}
}

// MARK: - Server side event

extension StreamDataRouter {
    public func startReceiveServerInitiatedDirective(resultHandler: ((Result<Downstream.Directive, Error>) -> Void)? = nil) {
        log.debug("start receive server initiated directives")
        serverSideEventDisposable = nuguApiProvider.directive
            .subscribe(onNext: { [weak self] in
                self?.notifyMessage(with: $0, resultHandler: resultHandler)
                }, onError: {
                    log.error("error: \($0)")
                    resultHandler?(.failure($0))
            })
        serverSideEventDisposable?.disposed(by: disposeBag)
    }
    
    public func stopReceiveServerInitiatedDirective() {
        log.debug("stop receive server initiated directives")
        serverSideEventDisposable?.dispose()
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
        let eventSender = EventSender()
        eventSenders[upstreamEventMessage.header.dialogRequestId] = eventSender
        
        // write event data to the stream
        eventSender.send(upstreamEventMessage)
            .subscribe(onCompleted: {
                completion?(.success(()))
            }, onError: { (error) in
                completion?(.failure(error))
            })
            .disposed(by: self.disposeBag)
        
        // request event as multi part stream
        nuguApiProvider.events(inputStream: eventSender.streams.input)
            .subscribe(onNext: { [weak self] (part) in
                self?.notifyMessage(with: part, resultHandler: resultHandler)
            }, onError: { (error) in
                log.error("error: \(error)")
                resultHandler?(.failure(error))
            }, onDisposed: { [weak self] in
                self?.eventSenders[upstreamEventMessage.header.dialogRequestId] = nil
            })
            .disposed(by: self.disposeBag)
    }
    
    public func sendStream(
        upstreamAttachment: UpstreamAttachment,
        completion: ((Result<Void, Error>) -> Void)?
    ) {
        guard let eventSender = eventSenders[upstreamAttachment.header.dialogRequestId] else {
            completion?(.failure(EventSenderError.noEventRequested))
            return
        }
        
        eventSender.send(upstreamAttachment)
            .subscribe(onCompleted: {
                if upstreamAttachment.isEnd {
                    eventSender.finish()
                }

                completion?(.success(()))
            }, onError: { (error) in
                completion?(.failure(error))
            })
            .disposed(by: disposeBag)
    }
    
    /**
     Preprocess directive and Call delegate's method and handler closure.
     */
    private func notifyMessage(with part: MultiPartParser.Part, resultHandler: ((Result<Downstream.Directive, Error>) -> Void)? = nil) {
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
                    delegate?.downstreamDataDidReceive(directive: directive)
                    resultHandler?(.success(directive))
            }
        } else if let attachment = Downstream.Attachment(headerDictionary: part.header, body: part.body) {
            if let attachment = self.downstreamDataTimeoutPreprocessor.preprocess(message: attachment) {
                delegate?.downstreamDataDidReceive(attachment: attachment)
            }
        } else {
            log.error("Invalid data \(part.header)")
        }
    }
    
    public func send(crashReports: [CrashReport]) {
        // TODO: send crash
//        guard let bodyData = try? JSONEncoder().encode(crashReports) else { return }
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
