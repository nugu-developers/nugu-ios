//
//  ChipsAgent.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/05/26.
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

public final class ChipsAgent: ChipsAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .chips, version: "1.0")
    
    // ExtensionAgentProtocol
    public weak var delegate: ChipsAgentDelegate?
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Render", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleRender)
    ]
    
    public init(
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        
        contextManager.add(delegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - ContextInfoDelegate

extension ChipsAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: (ContextInfo?) -> Void) {
        let payload: [String: AnyHashable?] = [
            "version": capabilityAgentProperty.version
        ]
        
        completion(
            ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload)
        )
    }
}

// MARK: - Private(Directive)

private extension ChipsAgent {
    func handleRender() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
            
            guard let item = try? JSONDecoder().decode(ChipsAgentItem.self, from: directive.payload) else {
                log.error("Invalid payload")
                return
            }
            
            self?.delegate?.chipsAgentDidReceive(item: item, dialogRequestId: directive.header.dialogRequestId)
        }
    }
}
