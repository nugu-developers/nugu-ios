//
//  MessageAgent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/05/06.
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

public class MessageAgent: CapabilityAgentable {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .message, version: "1.0")
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos: [DirectiveHandleInfo] = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SendCandidates", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSendCandidates),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SendMessage", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSendMessage),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "GetMessage", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleGetMessage),
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

extension MessageAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: @escaping (ContextInfo?) -> Void) {
        let payload: [String: AnyHashable?] = [
            "version": capabilityAgentProperty.version,
            // "candidates": [] // TODO: - Encoding from contacts
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

private extension MessageAgent {
    func handleSendCandidates() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
        }
    }
    
    func handleSendMessage() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
        }
    }
    
    func handleGetMessage() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
        }
    }
}
