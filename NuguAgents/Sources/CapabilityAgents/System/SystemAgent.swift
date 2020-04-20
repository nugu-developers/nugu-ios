//
//  SystemAgent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 24/05/2019.
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

public final class SystemAgent: SystemAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .system, version: "1.0")
    
    // Private
    private let contextManager: ContextManageable
    private let streamDataRouter: StreamDataRoutable
    private let directiveSequencer: DirectiveSequenceable
    private let systemDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.system_agent", qos: .userInitiated)
    
    private let delegates = DelegateSet<SystemAgentDelegate>()
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "HandoffConnection", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleHandOffConnection),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "UpdateState", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleUpdateState),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Exception", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleException),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Revoke", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleRevoke),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "NoDirectives", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: { { $1() } }),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Noop", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: { { $1() } })
    ]
    
    public init(
        contextManager: ContextManageable,
        streamDataRouter: StreamDataRoutable,
        directiveSequencer: DirectiveSequenceable
    ) {
        self.contextManager = contextManager
        self.streamDataRouter = streamDataRouter
        self.directiveSequencer = directiveSequencer
        
        contextManager.add(delegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - SystemAgentProtocol

public extension SystemAgent {
    func add(systemAgentDelegate: SystemAgentDelegate) {
        delegates.add(systemAgentDelegate)
    }
    
    func remove(systemAgentDelegate: SystemAgentDelegate) {
        delegates.remove(systemAgentDelegate)
    }
    
    func sendSynchronizeStateEvent() {
        sendSynchronizeStateEvent(directive: nil)
    }
}

// MARK: - ContextInfoDelegate

extension SystemAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: (ContextInfo?) -> Void) {
        let payload: [String: AnyHashable] = [
            "version": capabilityAgentProperty.version
        ]
        completion(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload))
    }

}

// MARK: - Private (handle directive)

private extension SystemAgent {
    func handleHandOffConnection() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
            
            guard let serverPolicy = try? JSONDecoder().decode(Policy.ServerPolicy.self, from: directive.payload) else {
                log.error("Invalid payload")
                return
            }
            self?.systemDispatchQueue.async { [weak self] in
                log.info("try to handoff policy: \(serverPolicy)")
                self?.streamDataRouter.handOffResourceServer(to: serverPolicy)
            }
        }
    }
    
    func handleUpdateState() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
        
            self?.sendSynchronizeStateEvent(directive: directive)
        }
    }
    
    func handleException() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
        
            guard let exceptionItem = try? JSONDecoder().decode(SystemAgentExceptionItem.self, from: directive.payload) else {
                log.error("Invalid payload")
                return
            }
            
            self?.systemDispatchQueue.async { [weak self] in
                switch exceptionItem.code {
                case .fail(let code):
                    self?.delegates.notify { delegate in
                        delegate.systemAgentDidReceiveExceptionFail(code: code)
                    }
                case .warning(let code):
                    log.debug("received warning code: \(code)")
                }
            }
        }
    }
    
    func handleRevoke() -> HandleDirective {
        return { [weak self] _, completion in
            defer { completion() }
            
            self?.systemDispatchQueue.async { [weak self] in
                self?.delegates.notify { delegate in
                    delegate.systemAgentDidReceiveRevokeDevice()
                }
            }
        }
    }
}

// MARK: - Private (handle directive)

private extension SystemAgent {
    func sendSynchronizeStateEvent(directive: Downstream.Directive? = nil) {
        contextManager.getContexts { [weak self] (contextPayload) in
            guard let self = self else { return }
            
            self.streamDataRouter.sendEvent(
                Event(
                    typeInfo: .synchronizeState
                ).makeEventMessage(
                    property: self.capabilityAgentProperty,
                    referrerDialogRequestId: directive?.header.dialogRequestId,
                    contextPayload: contextPayload
                )
            )
        }
    }
}
