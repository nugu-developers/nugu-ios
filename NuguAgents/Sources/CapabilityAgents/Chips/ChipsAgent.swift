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
import NuguUtils

public final class ChipsAgent: ChipsAgentProtocol, ContextInfoProvidable {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .chips, version: "1.1")
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    @Observing<ChipsAgentItem?> private var currentItem: ChipsAgentItem?
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Render", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleRender)
    ]
    
    public init(
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        
        contextManager.addProvider(contextInfoProvider)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    public var chipsItemObserverContainer: Observing<ChipsAgentItem?>.ObserverContainer { $currentItem }
    
    public lazy var contextInfoProvider: ProvideContextInfo = {
        return { [weak self] completion in
            guard let self = self else { return }
            
            let payload: [String: AnyHashable?] = [
                "version": self.capabilityAgentProperty.version
            ]
            
            completion(
                ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload)
            )
        }
    }()
}

// MARK: - Private(Directive)

private extension ChipsAgent {
    func handleRender() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let item = try? JSONDecoder().decode(ChipsAgentItem.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            
            self?._currentItem.additionalInfo = ["header": directive.header]
            self?.currentItem = item
        }
    }
}
