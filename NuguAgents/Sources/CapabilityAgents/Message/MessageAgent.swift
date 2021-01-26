//
//  MessageAgent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/01/06.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

public final class MessageAgent: MessageAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .message, version: "1.4")
    
    // MessageAgentProtocol
    public weak var delegate: MessageAgentDelegate?
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    private lazy var disposeBag = DisposeBag()
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos: [DirectiveHandleInfo] = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SendCandidates", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSendCandidates),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SendMessage", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSendMessage)
    ]
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
    }
    
    public init(
        directiveSequencer: DirectiveSequenceable,
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable
    ) {
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        var payload = [String: AnyHashable?]()
        
        if let context = self.delegate?.messageAgentRequestContext(),
            let contextData = try? JSONEncoder().encode(context),
            let contextDictionary = try? JSONSerialization.jsonObject(with: contextData, options: []) as? [String: AnyHashable] {
            payload = contextDictionary
        }
        
        payload["version"] = self.capabilityAgentProperty.version
        
        completion(ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
    }
}

// MARK: - MessageAgentProtocol

public extension MessageAgent {
    @discardableResult func requestSendCandidates(
        playServiceId: String,
        header: Downstream.Header?,
        completion: ((StreamDataState) -> Void)?
    ) -> String {
        let event = Event(
            typeInfo: .candidatesListed,
            playServiceId: playServiceId,
            referrerDialogRequestId: header?.dialogRequestId
        )
        
        return sendFullContextEvent(event.rx) { state in
            completion?(state)
        }.dialogRequestId
    }
}

// MARK: - Private(Directive)

private extension MessageAgent {
    func handleSendCandidates() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payloadDictionary = directive.payloadDictionary else {
                completion(.failed("Invalid payload"))
                return
            }
            
            guard let payloadData = try? JSONSerialization.data(withJSONObject: payloadDictionary, options: []),
                  let candidatesItem = try? JSONDecoder().decode(MessageCandidatesItem.self, from: payloadData) else {
                completion(.failed("Invalid candidateItem in payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.messageAgentDidReceiveSendCandidates(
                item: candidatesItem,
                header: directive.header
            )
        }
    }
    
    func handleSendMessage() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payloadDictionary = directive.payloadDictionary else {
                completion(.failed("Invalid payload"))
                return
            }
            
            guard let playServiceId = payloadDictionary["playServiceId"] as? String else {
                    completion(.failed("Invalid playServiceId in payload"))
                    return
            }
            
            guard let recipientDictionary = payloadDictionary["recipient"] as? [String: AnyHashable],
                let recipientData = try? JSONSerialization.data(withJSONObject: recipientDictionary, options: []),
                let recipient = try? JSONDecoder().decode(MessageAgentContact.self, from: recipientData) else {
                    completion(.failed("Invalid recipient in payload"))
                    return
            }
            
            defer { completion(.finished) }

            if let errorCode = delegate.messageAgentDidReceiveSendMessage(recipient: recipient, header: directive.header) {
                self.sendCompactContextEvent(Event(
                    typeInfo: .sendMessageFailed(recipient: recipient, errorCode: errorCode),
                    playServiceId: playServiceId,
                    referrerDialogRequestId: directive.header.dialogRequestId
                ).rx)
            } else {
                self.sendCompactContextEvent(Event(
                    typeInfo: .sendMessageSucceeded(recipient: recipient),
                    playServiceId: playServiceId,
                    referrerDialogRequestId: directive.header.dialogRequestId
                ).rx)
            }
        }
    }
}

// MARK: - Private (Event)

private extension MessageAgent {
    @discardableResult func sendCompactContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: contextManager.rxContexts(namespace: capabilityAgentProperty.name),
            property: capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
    
    @discardableResult func sendFullContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: contextManager.rxContexts(),
            property: capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
}
