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

public class PhoneCallAgent: PhoneCallAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .phoneCall, version: "1.0")
    
    // PhoneCallAgentProtocol
    public weak var delegate: PhoneCallAgentDelegate?
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos: [DirectiveHandleInfo] = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SendCandidates", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSendCandidates),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "MakeCall", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleMakeCall),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "EndCall", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleEndCall),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "AcceptCall", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleAcceptCall),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "BlockIncomingCall", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleBlockIncomingCall)
    ]
    
    public init(
        directiveSequencer: DirectiveSequenceable,
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable
    ) {
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
        
        contextManager.add(delegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - ContextInfoDelegate

extension PhoneCallAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: @escaping (ContextInfo?) -> Void) {
        let displayItem = delegate?.phoneCallAgentRequestDisplayItem()
        
        var payload: [String: AnyHashable?] = [
            "version": capabilityAgentProperty.version,
            "state": delegate?.phoneCallAgentRequestState().rawValue ?? PhoneCallState.idle.rawValue,
            "intent": displayItem?.intent?.rawValue,
            "callType": displayItem?.callType?.rawValue
        ]
        
        if let candidates = displayItem?.candidates,
            let candidatesData = try? JSONEncoder().encode(candidates),
            let candidatesArray = try? JSONSerialization.jsonObject(with: candidatesData, options: []) as? [[String: AnyHashable]] {
            
            payload["candidates"] = candidatesArray
        }
        
        completion(
            ContextInfo(
                contextType: .capability,
                name: capabilityAgentProperty.name,
                payload: payload.compactMapValues { $0 }
            )
        )
    }
}

// MARK: - Private(Directive)

private extension PhoneCallAgent {
    func handleSendCandidates() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
            
            guard let self = self else { return }
            
            guard let payloadDictionary = directive.payloadDictionary else {
                log.error("Invalid payload")
                return
            }
            
            guard let playServiceId = payloadDictionary["playServiceId"] as? String,
                let intent = payloadDictionary["intent"] as? String,
                let phoneCallIntent = PhoneCallIntent(rawValue: intent) else {
                    log.error("Invalid intent or playServiceId in payload")
                    return
            }
            
            guard let callType = payloadDictionary["callType"] as? String,
                let phoneCallType = PhoneCallType(rawValue: callType) else {
                    log.error("Invalid phoneCallType in payload")
                    return
            }
            
            var recipient: PhoneCallRecipient?
            if let recipientDictionary = payloadDictionary["recipient"] as? [String: AnyHashable],
                let recipientData = try? JSONSerialization.data(withJSONObject: recipientDictionary, options: []) {
                recipient = try? JSONDecoder().decode(PhoneCallRecipient.self, from: recipientData)
            }
            
            var candidates: [PhoneCallPerson]?
            if let candidatesArray = payloadDictionary["candidates"] as? [[String: AnyHashable]],
                let candidatesData = try? JSONSerialization.data(withJSONObject: candidatesArray, options: []) {
                candidates = try? JSONDecoder().decode([PhoneCallPerson].self, from: candidatesData)
            }
            
            let resultCandidates = self.delegate?.phoneCallAgentDidReceiveSendCandidates(
                intent: phoneCallIntent,
                callType: phoneCallType,
                recipient: recipient,
                candidates: candidates
            )
            
            self.contextManager.getContexts(namespace: self.capabilityAgentProperty.name) { [weak self] contextPayload in
                guard let self = self else { return }
                
                self.upstreamDataSender.sendEvent(
                    Event(
                        playServiceId: playServiceId,
                        typeInfo: .candidatesListed(intent: phoneCallIntent, callType: phoneCallType, recipient: recipient, candidates: resultCandidates)
                    ).makeEventMessage(
                        property: self.capabilityAgentProperty,
                        dialogRequestId: TimeUUID().hexString,
                        contextPayload: contextPayload
                    )
                )
            }
            
        }
    }
    
    func handleMakeCall() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
            
            guard let self = self else { return }
            
            guard let payloadDictionary = directive.payloadDictionary else {
                log.error("Invalid payload")
                return
            }
        
            guard let playServiceId = payloadDictionary["playServiceId"] as? String,
                let callType = payloadDictionary["callType"] as? String,
                let phoneCallType = PhoneCallType(rawValue: callType) else {
                    log.error("Invalid callType or playServiceId in payload")
                    return
            }
            
            guard let recipientDictionary = payloadDictionary["recipient"] as? [String: AnyHashable],
                let recipientData = try? JSONSerialization.data(withJSONObject: recipientDictionary, options: []),
                let recipientPerson = try? JSONDecoder().decode(PhoneCallPerson.self, from: recipientData) else {
                    log.error("Invalid recipient in payload")
                    return
            }
            
            if let errorCode = self.delegate?.phoneCallAgentDidReceiveMakeCall(callType: phoneCallType, recipient: recipientPerson) {
                // Failed to makeCall
                self.contextManager.getContexts(namespace: self.capabilityAgentProperty.name) { [weak self] contextPayload in
                    guard let self = self else { return }
                    
                    self.upstreamDataSender.sendEvent(
                        Event(
                            playServiceId: playServiceId,
                            typeInfo: .makeCallFailed(errorCode: errorCode, callType: phoneCallType)
                        ).makeEventMessage(
                            property: self.capabilityAgentProperty,
                            dialogRequestId: TimeUUID().hexString,
                            contextPayload: contextPayload
                        )
                    )
                }
            }
        }
    }
    
    func handleEndCall() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
            
            self?.delegate?.phoneCallAgentDidReceiveEndCall()
            
            // CHECK-ME: Send end-call event?
        }
    }
    
    func handleAcceptCall() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
            
            self?.delegate?.phoneCallAgentDidReceiveAcceptCall()
            
            // CHECK-ME: Send call-established event?
        }
    }
    
    // CHECK-ME: Is it necessary?
    func handleBlockIncomingCall() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
            
            self?.delegate?.phoneCallAgentDidReceiveBlockIncomingCall()
        }
    }
}
