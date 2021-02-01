//
//  PhoneCallAgent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/04/29.
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

public class PhoneCallAgent: PhoneCallAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .phoneCall, version: "1.2")
    
    // PhoneCallAgentProtocol
    public weak var delegate: PhoneCallAgentDelegate?
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    private let interactionControlManager: InteractionControlManageable
    
    private let phoneCallDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.phonecall_agent", qos: .userInitiated)
    
    // Current directive info
    private var currentMakeCallMessageId: String?
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos: [DirectiveHandleInfo] = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SendCandidates", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSendCandidates),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "MakeCall", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), preFetch: prefetchMakeCall, directiveHandler: handleMakeCall)
    ]
    
    private var disposeBag = DisposeBag()
    
    public init(
        directiveSequencer: DirectiveSequenceable,
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable,
        interactionControlManager: InteractionControlManageable
    ) {
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
        self.interactionControlManager = interactionControlManager
        
        contextManager.addProvider(contextInfoProvider)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        var payload = [String: AnyHashable?]()
        
        if let context = self.delegate?.phoneCallAgentRequestContext(),
            let contextData = try? JSONEncoder().encode(context),
            let contextDictionary = try? JSONSerialization.jsonObject(with: contextData, options: []) as? [String: AnyHashable] {
            payload = contextDictionary
        }
        
        payload["version"] = self.capabilityAgentProperty.version
        
        completion(
            ContextInfo(
                contextType: .capability,
                name: self.capabilityAgentProperty.name,
                payload: payload.compactMapValues { $0 }
            )
        )
    }
}

// MARK: - PhoneCallAgentProtocol

public extension PhoneCallAgent {
    @discardableResult func requestSendCandidates(
        candidatesItem: PhoneCallCandidatesItem,
        header: Downstream.Header?,
        completion: ((StreamDataState) -> Void)?
    ) -> String {
        let event = Event(
            typeInfo: .candidatesListed,
            playServiceId: candidatesItem.playServiceId,
            referrerDialogRequestId: header?.dialogRequestId
        )
        
        return sendFullContextEvent(event.rx) { [weak self] state in
            completion?(state)
            guard let self = self else { return }
            switch state {
            case .finished, .error:
                if let interactionControl = candidatesItem.interactionControl {
                    self.interactionControlManager.finish(
                        mode: interactionControl.mode,
                        category: self.capabilityAgentProperty.category
                    )
                }
            default:
                break
            }
        }.dialogRequestId
    }
}

// MARK: - Private(Directive)

private extension PhoneCallAgent {
    func handleSendCandidates() -> HandleDirective {
        return { [weak self] directive, completion in
            
            guard let self = self else {
                completion(.canceled)
                return
            }
            
            self.phoneCallDispatchQueue.async { [weak self] in
                guard let self = self, let delegate = self.delegate else {
                    completion(.canceled)
                    return
                }
                
                guard let payloadDictionary = directive.payloadDictionary else {
                    completion(.failed("Invalid payload"))
                    return
                }
                guard let payloadData = try? JSONSerialization.data(withJSONObject: payloadDictionary, options: []),
                    let candidatesItem = try? JSONDecoder().decode(PhoneCallCandidatesItem.self, from: payloadData) else {
                        completion(.failed("Invalid candidateItem in payload"))
                        return
                }
                
                defer { completion(.finished) }
                
                if let interactionControl = candidatesItem.interactionControl {
                    self.interactionControlManager.start(
                        mode: interactionControl.mode,
                        category: self.capabilityAgentProperty.category
                    )
                }
                
                delegate.phoneCallAgentDidReceiveSendCandidates(
                    item: candidatesItem,
                    header: directive.header
                )
            }
        }
    }
    
    func prefetchMakeCall() -> PrefetchDirective {
        return { [weak self] directive in
            self?.phoneCallDispatchQueue.sync { [weak self] in
                self?.currentMakeCallMessageId = directive.header.messageId
            }
        }
    }
    
    func handleMakeCall() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
            
            self.phoneCallDispatchQueue.async { [weak self] in
                guard let self = self else {
                    completion(.canceled)
                    return
                }
                
                guard self.currentMakeCallMessageId == directive.header.messageId else {
                    completion(.canceled)
                    log.info("Message id does not match")
                    return
                }
                
                guard let payloadDictionary = directive.payloadDictionary else {
                    completion(.failed("Invalid payload"))
                    return
                }
                
                guard let playServiceId = payloadDictionary["playServiceId"] as? String,
                    let callType = payloadDictionary["callType"] as? String,
                    let phoneCallType = PhoneCallType(rawValue: callType) else {
                        completion(.failed("Invalid callType or playServiceId in payload"))
                        return
                }
                
                guard let recipientDictionary = payloadDictionary["recipient"] as? [String: AnyHashable],
                    let recipientData = try? JSONSerialization.data(withJSONObject: recipientDictionary, options: []),
                    let recipientPerson = try? JSONDecoder().decode(PhoneCallPerson.self, from: recipientData) else {
                        completion(.failed("Invalid recipient in payload"))
                        return
                }
                
                defer { completion(.finished) }

                if let errorCode = self.delegate?.phoneCallAgentDidReceiveMakeCall(
                    callType: phoneCallType,
                    recipient: recipientPerson,
                    header: directive.header
                ) {
                    self.sendCompactContextEvent(Event(
                        typeInfo: .makeCallFailed(errorCode: errorCode, callType: phoneCallType),
                        playServiceId: playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    ).rx)
                } else {
                    self.sendCompactContextEvent(Event(
                        typeInfo: .makeCallSucceeded(recipient: recipientPerson),
                        playServiceId: playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    ).rx)
                }
            }
        }
    }
}

// MARK: - Private (Event)

private extension PhoneCallAgent {
    @discardableResult func sendCompactContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(namespace: self.capabilityAgentProperty.name),
            property: self.capabilityAgentProperty,
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
            context: self.contextManager.rxContexts(),
            property: self.capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
}
