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
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .phoneCall, version: "1.3")
    
    // PhoneCallAgentProtocol
    public weak var delegate: PhoneCallAgentDelegate?
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    private let interactionControlManager: InteractionControlManageable
    private var currentInteractionControl: InteractionControl?
    
    private let phoneCallDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.phonecall_agent", qos: .userInitiated)
    
    // Current directive info
    private var currentMakeCallMessageId: String?
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos: [DirectiveHandleInfo] = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SendCandidates", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSendCandidates),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "MakeCall", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), preFetch: prefetchMakeCall, directiveHandler: handleMakeCall),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "BlockNumber", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleBlockNumber)
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
        payload: PhoneCallAgentDirectivePayload.SendCandidates,
        header: Downstream.Header?,
        completion: ((StreamDataState) -> Void)?
    ) -> String {
        let event = Event(
            typeInfo: .candidatesListed(interactionControl: currentInteractionControl),
            playServiceId: payload.playServiceId,
            referrerDialogRequestId: header?.dialogRequestId
        )
        
        return sendFullContextEvent(event.rx) { [weak self] state in
            completion?(state)
            
            self?.phoneCallDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                switch state {
                case .finished, .error:
                    self.currentInteractionControl = nil
                    
                    if let interactionControl = payload.interactionControl {
                        self.interactionControlManager.finish(
                            mode: interactionControl.mode,
                            category: self.capabilityAgentProperty.category
                        )
                    }
                default:
                    break
                }
            }
        }.dialogRequestId
    }
}

// MARK: - Private(Directive)

private extension PhoneCallAgent {
    func handleSendCandidates() -> HandleDirective {
        return { [weak self] directive, completion in
            self?.phoneCallDispatchQueue.async { [weak self] in
                guard let self = self, let delegate = self.delegate else {
                    completion(.canceled)
                    return
                }
                
                guard let candidatesItem = try? JSONDecoder().decode(PhoneCallAgentDirectivePayload.SendCandidates.self, from: directive.payload) else {
                    completion(.failed("Invalid payload"))
                    return
                }
                
                if let interactionControl = candidatesItem.interactionControl {
                    self.currentInteractionControl = interactionControl
                    self.interactionControlManager.start(
                        mode: interactionControl.mode,
                        category: self.capabilityAgentProperty.category
                    )
                }
                
                delegate.phoneCallAgentDidReceiveSendCandidates(
                    payload: candidatesItem,
                    header: directive.header
                )
                
                completion(.finished)
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
                guard let self = self, let delegate = self.delegate else {
                    completion(.canceled)
                    return
                }
                
                guard self.currentMakeCallMessageId == directive.header.messageId else {
                    completion(.canceled)
                    log.info("Message id does not match")
                    return
                }
                
                guard let makeCallItem = try? JSONDecoder().decode(PhoneCallAgentDirectivePayload.MakeCall.self, from: directive.payload) else {
                    completion(.failed("Invalid payload"))
                    return
                }
                
                defer { completion(.finished) }
                
                let typeInfo: Event.TypeInfo
                if let errorCode = delegate.phoneCallAgentDidReceiveMakeCall(
                    payload: makeCallItem,
                    header: directive.header
                ) {
                    typeInfo = .makeCallFailed(errorCode: errorCode, callType: makeCallItem.callType)
                } else {
                    typeInfo = .makeCallSucceeded(recipient: makeCallItem.recipient)
                }
                
                self.sendCompactContextEvent(Event(
                    typeInfo: typeInfo,
                    playServiceId: makeCallItem.playServiceId,
                    referrerDialogRequestId: directive.header.dialogRequestId
                ).rx)
            }
        }
    }
    
    func handleBlockNumber() -> HandleDirective {
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
                
                guard let blockNumberItem = try? JSONDecoder().decode(PhoneCallAgentDirectivePayload.BlockNumber.self, from: directive.payload) else {
                    completion(.failed("Invalid payload"))
                    return
                }
                
                defer { completion(.finished) }
                
                delegate.phoneCallAgentDidReceiveBlockNumber(
                    payload: blockNumberItem,
                    header: directive.header
                )
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
