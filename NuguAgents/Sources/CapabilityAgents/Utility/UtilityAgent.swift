//
//  UtilityAgent.swift
//  NuguAgents
//
//  Created by 이민철님/AI Assistant개발Cell on 2021/01/04.
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

import Foundation

import NuguCore

public class UtilityAgent: UtilityAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .utility, version: "1.0")
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    
    private let utilityDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.utility_agent")
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos: [DirectiveHandleInfo] = [
        DirectiveHandleInfo(
            namespace: capabilityAgentProperty.name,
            name: "Block",
            blockingPolicy: BlockingPolicy(medium: .any, isBlocking: true),
            directiveHandler: handleBlock
        )
    ]
    
    public init(
        directiveSequencer: DirectiveSequenceable,
        contextManager: ContextManageable
    ) {
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        
        contextManager.addProvider(contextInfoProvider)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] (completion) in
        guard let self = self else { return }
        
        let payload: [String: AnyHashable] = [
            "version": self.capabilityAgentProperty.version
        ]
        completion(ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload))
    }
}

// MARK: - Private(Directive)

private extension UtilityAgent {
    func handleBlock() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
            guard let item = try? JSONDecoder().decode(UtilityBlockItem.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            self.utilityDispatchQueue.asyncAfter(deadline: .now() + item.sleep) {
                completion(.finished)
            }
        }
    }
}
