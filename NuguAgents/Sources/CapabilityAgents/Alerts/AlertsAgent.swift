//
//  AlertsAgent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/02/26.
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

public class AlertsAgent: AlertsAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = .init(category: .alerts, version: "1.1")
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos: [DirectiveHandleInfo] = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SetAlert", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSetAlert),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "DeleteAlerts", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleDeleteAlerts),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "DeliveryAlertAsset", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleDeliveryAlertAsset),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SetSnooze", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSetSnooze)
    ]
    
    public init(
        directiveSequencer: DirectiveSequenceable,
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable
    ) {
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
        
        contextManager.addProvider(contextInfoProvider)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        var payload = [String: AnyHashable?]()
        
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

// MARK: - Private(Directive)

private extension AlertsAgent {
    func handleSetAlert() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
        }
    }
    
    func handleDeleteAlerts() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
        }
    }
    
    func handleDeliveryAlertAsset() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
        }
    }
    
    func handleSetSnooze() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
        }
    }
}
