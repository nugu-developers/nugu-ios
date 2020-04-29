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
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    // temp
    private var state: String = ""
    private var intent: String = ""
    private var callType: String = ""
    private var candidates: [String] = []
    
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
        let payload: [String: AnyHashable?] = [
            "version": capabilityAgentProperty.version,
            "state": state,
            "intent": intent,
            "callType": callType,
            "candidates": candidates
        ]
        
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
        }
    }
    
    func handleMakeCall() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
        }
    }
    
    func handleEndCall() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
        }
    }
    
    func handleAcceptCall() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
        }
    }
    
    func handleBlockIncomingCall() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
        }
    }
}
