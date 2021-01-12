//
//  SessionAgent.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/05/28.
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

import NuguCore

public final class SessionAgent: SessionAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .session, version: "1.0")
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let sessionManager: SessionManageable
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Set", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSet)
    ]
    
    public init(
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable,
        sessionManager: SessionManageable
    ) {
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        self.sessionManager = sessionManager
        
        contextManager.addProvider(contextInfoProvider)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        let sessions = self.sessionManager.activeSessions
            .reduce(into: [Session]()) { (result, session) in
                result.removeAll { $0.playServiceId == session.playServiceId }
                result.append(session)
            }
            .map { ["sessionId": $0.sessionId, "playServiceId": $0.playServiceId] }
                
        let payload: [String: AnyHashable?] = [
            "version": self.capabilityAgentProperty.version,
            "list": sessions
        ]
        
        completion(
            ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 })
        )
    }
}

// MARK: - Private(Directive)

private extension SessionAgent {
    func handleSet() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let item = try? JSONDecoder().decode(SessionAgentItem.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }

            let session = Session(sessionId: item.sessionId, dialogRequestId: directive.header.dialogRequestId, playServiceId: item.playServiceId)
            self?.sessionManager.set(session: session)
        }
    }
}
