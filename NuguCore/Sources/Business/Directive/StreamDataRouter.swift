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
    public weak var delegate: StreamDataDelegate?
    
    private let nuguApiProvider = NuguApiProvider()
    private let directiveSequencer: DirectiveSequenceable
    private var eventSenders = EventSenders()
    private var serverInitiatedDirectiveRecever: ServerSideEventReceiver
    private var serverInitiatedDirectiveCompletion: ((StreamDataState) -> Void)?
    private var serverInitiatedDirectiveDisposable: Disposable?
    private let disposeBag = DisposeBag()
    
    public init(directiveSequencer: DirectiveSequenceable) {
        serverInitiatedDirectiveRecever = ServerSideEventReceiver(apiProvider: nuguApiProvider)
        self.directiveSequencer = directiveSequencer
    }
}

// MARK: - APIs for Server side event

public extension StreamDataRouter {
    func startReceiveServerInitiatedDirective(completion: ((StreamDataState) -> Void)? = nil) {
        // Store completion closure to use continuously.
        // Though the resource is changed by handoff command from server.
        serverInitiatedDirectiveCompletion = completion
        
        log.debug("start receive server initiated directives")

        serverInitiatedDirectiveDisposable?.dispose()
        serverInitiatedDirectiveDisposable = serverInitiatedDirectiveRecever.directive
            .subscribe(onNext: { [weak self] in
                    self?.notifyMessage(with: $0, completion: completion)
                }, onError: {
                    log.error("error: \($0)")
                    completion?(.error($0))
                }, onDisposed: {
                    log.debug("server initiated directive is stopeed")
                })
        serverInitiatedDirectiveDisposable?.disposed(by: disposeBag)
    }
    
    func stopReceiveServerInitiatedDirective() {
        log.debug("stop receive server initiated directives")
        serverInitiatedDirectiveDisposable?.dispose()
        serverInitiatedDirectiveCompletion = nil
    }
    
    func handOffResourceServer(to serverPolicy: Policy.ServerPolicy) {
        log.debug("change resource server to: https://\(serverPolicy.hostname).\(serverPolicy.port)")
        stopReceiveServerInitiatedDirective()
        serverInitiatedDirectiveRecever.serverPolicies.removeAll()
        serverInitiatedDirectiveRecever.serverPolicies.append(serverPolicy)
        
        // Use stored completion closure before.
        startReceiveServerInitiatedDirective(completion: serverInitiatedDirectiveCompletion)
    }
}

// MARK: - APIs for send event

public extension StreamDataRouter {
    /**
     Sends an event and close the stream automatically.
     
     This method is for the event which is not related attachment.
     */
    func sendEvent(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)? = nil) {
        sendStream(event) { [weak self] result in
            // close stream automatically.
            if case .sent = result {
                self?.eventSenders[event.header.dialogRequestId]?.finish()
            }

            completion?(result)
        }
    }
    
    /**
     Sends an event and keep the stream alive for futrue attachment.
     
     Event must be sent before sending attachment.
     And It cannot be sent twice.
     */
    func sendStream(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)? = nil) {
        let boundary = HTTPConst.boundaryPrefix + event.header.dialogRequestId
        let eventSender = EventSender(boundary: boundary)
        eventSenders[event.header.dialogRequestId] = eventSender
        
        // write event data to the stream
        eventSender.send(event)
            .subscribe(onCompleted: {
                completion?(.sent)
            }, onError: { [weak self] (error) in
                completion?(.error(error))
                self?.delegate?.streamDataDidSend(event: event, error: error)
            })
            .disposed(by: self.disposeBag)
        
        // request event as multi part stream
        nuguApiProvider.events(boundary: boundary, inputStream: eventSender.streams.input)
            .subscribe(onNext: { [weak self] (part) in
                self?.notifyMessage(with: part, completion: completion)
            }, onError: { [weak self] (error) in
                log.error("\(error.localizedDescription)")
                completion?(.error(error))
                self?.delegate?.streamDataDidSend(event: event, error: error)
            }, onCompleted: { [weak self] in
                completion?(.finished)
                self?.delegate?.streamDataDidSend(event: event, error: nil)
            }, onDisposed: { [weak self] in
                self?.eventSenders[event.header.dialogRequestId] = nil
            })
            .disposed(by: self.disposeBag)
    }
    
    /**
     Sends an attachment.
     
     It won't emit received or finished state on completion.
     because those states will be emitted to event-request's completion.
     */
    func sendStream(_ attachment: Upstream.Attachment, dialogRequestId: String, completion: ((StreamDataState) -> Void)? = nil) {
        guard let eventSender = eventSenders[dialogRequestId] else {
            completion?(.error(EventSenderError.noEventRequested))
            delegate?.streamDataDidSend(attachment: attachment, error: EventSenderError.noEventRequested)
            return
        }
        
        eventSender.send(attachment)
            .subscribe(onCompleted: { [weak self] in
                if attachment.header.isEnd {
                    eventSender.finish()
                }

                completion?(.sent)
                self?.delegate?.streamDataDidSend(attachment: attachment, error: nil)
            }, onError: { [weak self] (error) in
                completion?(.error(error))
                self?.delegate?.streamDataDidSend(attachment: attachment, error: error)
            })
            .disposed(by: disposeBag)
    }
    
    func cancelEvent(dialogRequestId: String) {
        guard let eventSender = eventSenders[dialogRequestId] else { return }

        eventSender.finish()
    }
}

// MARK: - private
extension StreamDataRouter {
    /**
     Send directive or attachment to `DirectiveSequencer` and Call closure
     
     Multiple Directives can be delivered at once.
     But we can process every single directive separately using this method
     */
    private func notifyMessage(with part: MultiPartParser.Part, completion: ((StreamDataState) -> Void)? = nil) {
        if let contentType = part.header["Content-Type"], contentType.contains("application/json") {
            guard let bodyDictionary = try? JSONSerialization.jsonObject(with: part.body, options: []) as? [String: AnyHashable],
                let directiveArray = bodyDictionary["directives"] as? [[String: AnyHashable]] else {
                    log.error("Decode Message failed")
                    completion?(.error(NetworkError.invalidMessageReceived))
                    return
            }
            
            directiveArray
                .compactMap(Downstream.Directive.init)
                .forEach { directive in
                    directiveSequencer.processDirective(directive)
                    completion?(.received(part: directive))
                    delegate?.streamDataDidReceive(direcive: directive)
            }
        } else if let attachment = Downstream.Attachment(headerDictionary: part.header, body: part.body) {
            directiveSequencer.processAttachment(attachment)
            delegate?.streamDataDidReceive(attachment: attachment)
        } else {
            log.error("Invalid data \(part.header)")
        }
    }
}

// MARK: - Downstream.Attachment initializer

private extension Downstream.Attachment {
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

private extension Downstream.Directive {
    init?(directiveDictionary: [String: AnyHashable]) {
        guard let headerDictionary = directiveDictionary["header"] as? [String: AnyHashable],
            let headerData = try? JSONSerialization.data(withJSONObject: headerDictionary, options: []),
            let header = try? JSONDecoder().decode(Downstream.Header.self, from: headerData),
            let payloadDictionary = directiveDictionary["payload"] as? [String: AnyHashable],
            let payload = try? JSONSerialization.data(withJSONObject: payloadDictionary, options: []) else {
                return nil
        }
        
        self.init(header: header, payload: payload)
    }
}

// MARK: - Downstream.Header initializer

private extension Downstream.Header {
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
