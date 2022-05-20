//
//  MessengerAgent.swift
//  NuguMessengerAgent
//
//  Created by yonghoonKwon on 2021/04/12.
//  Copyright (c) 2021 SK Telecom Co., Ltd. All rights reserved.
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

import NuguCore

import RxSwift

public class MessengerAgent {
    public var capabilityAgentProperty: CapabilityAgentProperty = .init(category: .plugin(name: "Messenger"), version: "1.0")
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    public weak var delegate: MessengerAgentDelegate?
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos: [DirectiveHandleInfo] = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CreateSucceeded", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleCreateSucceeded),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Configure", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleConfigure),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SendHistory", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSendHistory),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "NotifyMessage", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleNotifyMessage),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "NotifyStartDialog", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleNotifyStartDialog),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "NotifyStopDialog", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleNotifyStopDialog),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "NotifyRead", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleNotifyRead),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "NotifyReaction", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleNotifyReaction),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "MessageRedirect", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleMessageRedirect)
    ]
    
    private lazy var disposeBag = DisposeBag()
    
    public init(
        directiveSequencer: DirectiveSequenceable,
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable
    ) {
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
        
        contextManager.addProvider(contextInfoProvider)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] (completion) in
        guard let self = self else { return }
        
        var payload = [String: AnyHashable?]()
        
        if let context = self.delegate?.messengerAgentRequestContext(),
            let contextData = try? JSONEncoder().encode(context),
            let contextDictionary = try? JSONSerialization.jsonObject(with: contextData, options: []) as? [String: AnyHashable] {
            payload = contextDictionary
        }
        
        payload["version"] = self.capabilityAgentProperty.version
        
        completion(
            ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 })
        )
    }
}

// MARK: - Events

public extension MessengerAgent {
    @discardableResult func requestCreate(
        playServiceId: String,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        return sendCompactContextEvent(
            Event(
                typeInfo: .create(playServiceId: playServiceId),
                referrerDialogRequestId: nil
            ).rx,
            completion: completion
        ).dialogRequestId
    }
    
    @discardableResult func requestSync(
        item: MessengerAgentEventPayload.Sync,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        return sendCompactContextEvent(
            Event(
                typeInfo: .sync(item: item),
                referrerDialogRequestId: nil
            ).rx,
            completion: completion
        ).dialogRequestId
    }
    
    @discardableResult func requestEnter(
        item: MessengerAgentEventPayload.Enter,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        return sendCompactContextEvent(
            Event(
                typeInfo: .enter(item: item),
                referrerDialogRequestId: nil
            ).rx,
            completion: completion
        ).dialogRequestId
    }
    
    @discardableResult func requestRead(
        roomId: String,
        readMessageId: String,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        return sendCompactContextEvent(
            Event(
                typeInfo: .read(roomId: roomId, readMessageId: readMessageId),
                referrerDialogRequestId: nil
            ).rx,
            completion: completion
        ).dialogRequestId
    }
    
    @discardableResult func requestMessage(
        item: MessengerAgentEventPayload.Message,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        return sendCompactContextEvent(
            Event(
                typeInfo: .message(item: item),
                referrerDialogRequestId: nil
            ).rx,
            completion: completion
        ).dialogRequestId
    }
    
    @discardableResult func requestExit(
        roomId: String,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        return sendCompactContextEvent(
            Event(
                typeInfo: .exit(roomId: roomId),
                referrerDialogRequestId: nil
            ).rx,
            completion: completion
        ).dialogRequestId
    }
    
    @discardableResult func requestReaction(
        item: MessengerAgentEventPayload.Reaction,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        return sendCompactContextEvent(
            Event(
                typeInfo: .reaction(item: item),
                referrerDialogRequestId: nil
            ).rx,
            completion: completion
        ).dialogRequestId
    }
}

// MARK: - Private(Directive)

private extension MessengerAgent {
    func handleCreateSucceeded() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MessengerAgentDirectivePayload.CreateSucceeded.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self.sendDirectiveDelivered(
                dialogRequestId: directive.header.dialogRequestId,
                roomId: payload.roomId
            )
            
            delegate.messengerAgentDidReceiveCreateSucceeded(
                payload: payload,
                header: directive.header
            )
        }
    }
    
    func handleConfigure() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MessengerAgentDirectivePayload.Configure.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self.sendDirectiveDelivered(
                dialogRequestId: directive.header.dialogRequestId,
                roomId: payload.roomId
            )
            
            delegate.messengerAgentDidReceiveConfigure(
                payload: payload,
                header: directive.header
            )
        }
    }
    
    func handleSendHistory() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MessengerAgentDirectivePayload.SendHistory.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self.sendDirectiveDelivered(
                dialogRequestId: directive.header.dialogRequestId,
                roomId: payload.roomId
            )
            
            delegate.messengerAgentDidReceiveSendHistory(
                payload: payload,
                header: directive.header
            )
        }
    }
    
    func handleNotifyMessage() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MessengerAgentDirectivePayload.NotifyMessage.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self.sendDirectiveDelivered(
                dialogRequestId: directive.header.dialogRequestId,
                roomId: payload.roomId
            )
            
            delegate.messengerAgentDidReceiveNotifyMessage(
                payload: payload,
                header: directive.header
            )
        }
    }
    
    func handleNotifyStartDialog() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MessengerAgentDirectivePayload.NotifyStartDialog.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self.sendDirectiveDelivered(
                dialogRequestId: directive.header.dialogRequestId,
                roomId: payload.roomId
            )
            
            delegate.messengerAgentDidReceiveNotifyStartDialog(
                payload: payload,
                header: directive.header
            )
        }
    }
    
    func handleNotifyStopDialog() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MessengerAgentDirectivePayload.NotifyStopDialog.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self.sendDirectiveDelivered(
                dialogRequestId: directive.header.dialogRequestId,
                roomId: payload.roomId
            )
            
            delegate.messengerAgentDidReceiveNotifyStopDialog(
                payload: payload,
                header: directive.header
            )
        }
    }
    
    func handleNotifyRead() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MessengerAgentDirectivePayload.NotifyRead.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self.sendDirectiveDelivered(
                dialogRequestId: directive.header.dialogRequestId,
                roomId: payload.roomId
            )
            
            delegate.messengerAgentDidReceiveNotifyRead(
                payload: payload,
                header: directive.header
            )
        }
    }
    
    func handleNotifyReaction() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MessengerAgentDirectivePayload.NotifyReaction.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self.sendDirectiveDelivered(
                dialogRequestId: directive.header.dialogRequestId,
                roomId: payload.roomId
            )
            
            delegate.messengerAgentDidReceiveNotifyReaction(
                payload: payload,
                header: directive.header
            )
        }
    }
    
    func handleMessageRedirect() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MessengerAgentDirectivePayload.MessageRedirect.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.messengerAgentDidReceiveMessageRedirect(
                payload: payload,
                header: directive.header
            )
        }
    }
}

// MARK: - Private(Event)

private extension MessengerAgent {
    @discardableResult func sendCompactContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(namespace: self.capabilityAgentProperty.name),
            property: capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
    
    @discardableResult func sendDirectiveDelivered(
        dialogRequestId: String,
        roomId: String,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        return sendCompactContextEvent(
            Event(
                typeInfo: .directiveDelivered(roomId: roomId),
                referrerDialogRequestId: dialogRequestId
            ).rx,
            completion: completion
        ).dialogRequestId
    }
}
