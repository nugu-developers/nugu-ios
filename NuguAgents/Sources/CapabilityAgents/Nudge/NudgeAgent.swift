//
//  NudgeAgent.swift
//  NuguAgents
//
//  Created by chidlc on 2021/03/15.
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
import NuguUtils

public class NudgeAgent: NudgeAgentProtocol {
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private var nudgeInfo: [String: AnyHashable]?
    private var dialogRequestId: String?
    
    public let capabilityAgentProperty = CapabilityAgentProperty(category: .nudge, version: "1.0")
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] (completion) in
        guard let self = self else { return }
        
        let payload: [String: AnyHashable?] = [
            "version": self.capabilityAgentProperty.version,
            "nudgeInfo": self.nudgeInfo
        ]
        
        completion(ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
    }
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var playSyncObserver: Any?
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Append", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), preFetch: prefetchAppend, directiveHandler: dummyHandler)
    ]
    
    public init(
        directiveSequencer: DirectiveSequenceable,
        contextManager: ContextManageable,
        playSyncManager: PlaySyncManageable
    ) {
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        contextManager.addProvider(contextInfoProvider)
        
        playSyncObserver = playSyncManager.observe(NuguCoreNotification.PlaySync.SynchronizedProperties.self, queue: nil) { [weak self] (notification) in
            if (notification.properties.contains { $0.info.dialogRequestId == self?.dialogRequestId }) == false {
                self?.nudgeInfo = nil
            }
        }
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        contextManager.removeProvider(contextInfoProvider)
        
        if let playSyncObserver = playSyncObserver {
            notificationCenter.removeObserver(playSyncObserver)
            self.playSyncObserver = nil
        }
    }
}

extension NudgeAgent {
    func prefetchAppend() -> PrefetchDirective {
        return { [weak self] (directive) in
            guard let nudgeInfo = directive.payloadDictionary?["nudgeInfo"] as? [String: AnyHashable] else {
                return
            }
            
            self?.nudgeInfo = nudgeInfo
            self?.dialogRequestId = directive.header.dialogRequestId
        }
    }
    
    func dummyHandler() -> HandleDirective {
        return { (_, completion) in
            completion(.finished)
        }
    }
}
