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

import NuguUtils

import RxSwift

public class StreamDataRouter: StreamDataRoutable {
    private let notificationQueue = DispatchQueue(label: "com.sktelecom.romaine.stream_data_router_notificaiton_queue")
    
    private let nuguApiProvider = NuguApiProvider()
    private let directiveSequencer: DirectiveSequenceable
    @Atomic private var eventSenders = [String: EventSender]()
    @Atomic private var eventDisposables = [String: Disposable]()
    private var serverInitiatedDirectiveReceiver: ServerSideEventReceiver
    private var serverInitiatedDirectiveCompletion: ((StreamDataState) -> Void)?
    private var serverInitiatedDirectiveDisposable: Disposable?
    private var serverInitiatedDirectiveStateDisposable: Disposable?
    private let disposeBag = DisposeBag()
    
    public init(directiveSequencer: DirectiveSequenceable) {
        serverInitiatedDirectiveReceiver = ServerSideEventReceiver(apiProvider: nuguApiProvider)
        self.directiveSequencer = directiveSequencer
    }
}

// MARK: - APIs for Server side event

public extension StreamDataRouter {
    /**
     Connect to the server and keep it.
     
     The server can send some directives at certain times.
     */
    func startReceiveServerInitiatedDirective(completion: ((StreamDataState) -> Void)? = nil) {
        // Store completion closure to use continuously.
        // Though the resource is changed by handoff command from server.
        serverInitiatedDirectiveCompletion = completion
        
        serverInitiatedDirectiveStateDisposable?.dispose()
        serverInitiatedDirectiveStateDisposable = serverInitiatedDirectiveReceiver.stateObserver
            .subscribe(onNext: { [weak self] state in
                self?.notificationQueue.async { [weak self] in
                    self?.post(state)
                }
            })
        serverInitiatedDirectiveStateDisposable?.disposed(by: disposeBag)
        
        log.debug("start receive server initiated directives")
        serverInitiatedDirectiveDisposable?.dispose()
        serverInitiatedDirectiveDisposable = serverInitiatedDirectiveReceiver.directive
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
    
    /**
     Connect to the server with specific policy and keep it.
     The server can send some directives at certain times.
     */
    func startReceiveServerInitiatedDirective(to serverPolicy: Policy.ServerPolicy) {
        log.debug("change resource server to: https://\(serverPolicy.hostname).\(serverPolicy.port)")
        
        // Use stored completion closure before.
        startReceiveServerInitiatedDirective(completion: serverInitiatedDirectiveCompletion)
    }
    
    /**
     Reset exist connection policy and request new connection
     */
    func restartReceiveServerInitiatedDirective() {
        // Use stored completion closure before.
        startReceiveServerInitiatedDirective(completion: serverInitiatedDirectiveCompletion)
    }
    
    /**
     Stop receiving server-initiated-directive.
     */
    func stopReceiveServerInitiatedDirective() {
        log.debug("stop receive server initiated directives")
        serverInitiatedDirectiveDisposable?.dispose()
        serverInitiatedDirectiveStateDisposable?.dispose()
        serverInitiatedDirectiveCompletion = nil
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
        _eventSenders.mutate {
            $0[event.header.dialogRequestId] = eventSender
        }
        
        // write event data to the stream
        log.debug("Event: \(event.header.dialogRequestId), \(event.header.namespace).\(event.header.name)")
        self.notificationQueue.async { [weak self] in
            self?.post(NuguCoreNotification.StreamDataRoute.ToBeSentEvent(event: event))
        }
        
        eventSender.send(event)
        completion?(.sent)
        
        // request event as multi part stream
        _eventDisposables.mutate {
            $0[event.header.dialogRequestId] = nuguApiProvider.events(boundary: boundary, httpHeaderFields: event.httpHeaderFields, inputStream: eventSender.inputStream)
                .subscribe(onNext: { [weak self] (part) in
                    self?.notifyMessage(with: part, completion: completion)
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    
                    log.error("\(error.localizedDescription)")
                    self.notificationQueue.async { [weak self] in
                        self?.post(NuguCoreNotification.StreamDataRoute.SentEvent(event: event, error: error))
                    }
                    
                    completion?(.error(error))
                }, onCompleted: { [weak self] in
                    guard let self = self else { return }
                    
                    self.notificationQueue.async { [weak self] in
                        self?.post(NuguCoreNotification.StreamDataRoute.SentEvent(event: event, error: nil))
                    }
                    
                    // Restart server initiated directive receiver if it was disconnected with error
                    if case .disconnected = self.serverInitiatedDirectiveReceiver.state {
                        self.startReceiveServerInitiatedDirective(completion: self.serverInitiatedDirectiveCompletion)
                    }
                    
                    completion?(.finished)
                }, onDisposed: { [weak self] in
                    self?._eventDisposables.mutate {
                        $0[event.header.dialogRequestId] = nil
                    }
                    
                    self?._eventSenders.mutate {
                        $0[event.header.dialogRequestId] = nil
                    }
                })
        }
    }
    
    /**
     Sends an attachment.
     
     It won't emit received or finished state on completion.
     because those states will be emitted to event-request's completion.
     */
    func sendStream(_ attachment: Upstream.Attachment, completion: ((StreamDataState) -> Void)? = nil) {
        guard let eventSender = eventSenders[attachment.header.dialogRequestId] else {
            self.notificationQueue.async { [weak self] in
                self?.post(NuguCoreNotification.StreamDataRoute.SentAttachment(attachment: attachment, error: EventSenderError.noEventRequested))
            }
            
            completion?(.error(EventSenderError.noEventRequested))
            return
        }

        log.debug("Attachment: \(attachment)")
        eventSender.send(attachment)
        
        if attachment.isEnd {
            eventSender.finish()
        }

        self.notificationQueue.async { [weak self] in
            self?.post(NuguCoreNotification.StreamDataRoute.SentAttachment(attachment: attachment, error: nil))
        }

        completion?(.sent)
    }
    
    /**
     Cancel sending event.
     */
    func cancelEvent(dialogRequestId: String) {
        eventSenders[dialogRequestId]?.finish()
        eventDisposables[dialogRequestId]?.dispose()
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
            
            let directives = directiveArray.compactMap(Downstream.Directive.init)
            post(NuguCoreNotification.StreamDataRoute.ReceivedDirectives(directives: directives))
            
            directives.forEach { directive in
                log.debug("Directive: \(directive.header)")
                self.notificationQueue.async { [weak self] in
                    self?.post(NuguCoreNotification.StreamDataRoute.ReceivedDirective(directive: directive))
                }
                
                directiveSequencer.processDirective(directive)
                completion?(.received(part: directive))
            }
        } else if let attachment = Downstream.Attachment(headerDictionary: part.header, body: part.body) {
            log.debug("Attachment: \(attachment.header.dialogRequestId), \(attachment.header.type)")
            self.notificationQueue.async { [weak self] in
                self?.post(NuguCoreNotification.StreamDataRoute.ReceivedAttachment(attachment: attachment))
            }
            
            directiveSequencer.processAttachment(attachment)
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

public extension Downstream.Directive {
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
            let version = headerDictionary["Version"],
            let messageId = headerDictionary["Message-Id"] else {
                return nil
        }
        
        self.init(namespace: namespace, name: name, dialogRequestId: dialogRequestId, messageId: messageId, version: version)
    }
}

// MARK: - Observer

extension Notification.Name {
    static let streamDataDirectivesDidReceive = Notification.Name("com.sktelecom.romaine.notification.name.stream_data_directives_did_receive")
    static let streamDataDirectiveDidReceive = Notification.Name("com.sktelecom.romaine.notification.name.stream_data_directive_did_receive")
    static let streamDataAttachmentDidReceive = Notification.Name("com.sktelecom.romaine.notification.name.stread_data_attachment_did_receive")
    static let streamDataEventWillSend = Notification.Name("com.sktelecom.romaine.notification.name.stream_data_event_will_send")
    static let streamDataEventDidSend = Notification.Name("com.sktelecom.romaine.notification.name.stream_data_event_did_send")
    static let streamDataAttachmentDidSend = Notification.Name("com.sktelecom.romaine.notification.name.stream_data_attachment_did_send")
}

public extension NuguCoreNotification {
    enum StreamDataRoute {
        public struct ReceivedDirectives: TypedNotification {
            public static var name: Notification.Name = .streamDataDirectivesDidReceive
            public let directives: [Downstream.Directive]

            public static func make(from: [String: Any]) -> ReceivedDirectives? {
                guard let directives = from["directives"] as? [Downstream.Directive] else { return nil }

                return ReceivedDirectives(directives: directives)
            }
        }

        public struct ReceivedDirective: TypedNotification {
            public static var name: Notification.Name = .streamDataDirectiveDidReceive
            public let directive: Downstream.Directive
            
            public static func make(from: [String: Any]) -> ReceivedDirective? {
                guard let directive = from["directive"] as? Downstream.Directive else { return nil }
                
                return ReceivedDirective(directive: directive)
            }
        }
        
        public struct ReceivedAttachment: TypedNotification {
            public static var name: Notification.Name = .streamDataAttachmentDidReceive
            public let attachment: Downstream.Attachment
            
            public static func make(from: [String: Any]) -> ReceivedAttachment? {
                guard let attachment = from["attachment"] as? Downstream.Attachment else { return nil }
                
                return ReceivedAttachment(attachment: attachment)
            }
        }
        
        public struct ToBeSentEvent: TypedNotification {
            public static let name: Notification.Name = .streamDataEventWillSend
            public let event: Upstream.Event
            
            public static func make(from: [String: Any]) -> ToBeSentEvent? {
                guard let event = from["event"] as? Upstream.Event else { return nil }
                
                return ToBeSentEvent(event: event)
            }
        }
        
        public struct SentEvent: TypedNotification {
            public static var name: Notification.Name = .streamDataEventDidSend
            public let event: Upstream.Event
            public let error: Error?
            
            public static func make(from: [String: Any]) -> SentEvent? {
                guard let event = from["event"] as? Upstream.Event else { return nil }
                
                let error = from["error"] as? Error
                return SentEvent(event: event, error: error)
            }
        }
        
        public struct SentAttachment: TypedNotification {
            public static var name: Notification.Name = .streamDataAttachmentDidSend
            public let attachment: Upstream.Attachment
            public let error: Error?
            
            public static func make(from: [String: Any]) -> SentAttachment? {
                guard let attachment = from["attachment"] as? Upstream.Attachment else { return nil }
                
                let error = from["error"] as? Error
                return SentAttachment(attachment: attachment, error: error)
            }
        }
        
        public typealias ServerInitiatedDirectiveReceiverState = ServerSideEventReceiverState
    }
}
