//
//  PermissionAgent.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2021/03/19.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
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

public class PermissionAgent: PermissionAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .permission, version: "1.0")
    
    // PermissionAgentProtocol
    public weak var delegate: PermissionAgentDelegate?
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "RequestPermission", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleRequestPermission)
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
        contextManager.removeProvider(contextInfoProvider)
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        var payload = [String: AnyHashable?]()
        
        if let context = self.delegate?.permissionAgentRequestContext(),
            let contextData = try? JSONEncoder().encode(context),
            let contextDictionary = try? JSONSerialization.jsonObject(with: contextData, options: []) as? [String: AnyHashable] {
            payload = contextDictionary
        }
        
        payload["version"] = self.capabilityAgentProperty.version
        
        completion(
            ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 })
        )
    }
}

// MARK: - Private(Directive)

private extension PermissionAgent {
    func handleRequestPermission() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let item = try? JSONDecoder().decode(PermissionAgentDirectivePayload.RequestPermission.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }

            self?.delegate?.permissionAgentDidReceiveRequestPermission(payload: item, header: directive.header)
        }
    }
}
