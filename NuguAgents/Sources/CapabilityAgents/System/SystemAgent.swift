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

open class SystemAgent: SystemAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .system, version: "1.0")
    
    // Private
    private let contextManager: ContextManageable
    private let networkManager: NetworkManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    private let systemDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.system_agent", qos: .userInitiated)
    
    private let delegates = DelegateSet<SystemAgentDelegate>()
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "HandoffConnection", medium: .none, isBlocking: false, handler: handleHandOffConnection),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "UpdateState", medium: .none, isBlocking: false, handler: handleUpdateState),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Exception", medium: .none, isBlocking: false, handler: handleException),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "NoDirectives", medium: .none, isBlocking: false, handler: { { $1(.success(())) } })
    ]
    
    public init(
        contextManager: ContextManageable,
        networkManager: NetworkManageable,
        upstreamDataSender: UpstreamDataSendable,
        directiveSequencer: DirectiveSequenceable
    ) {
        log.info("")
        
        self.contextManager = contextManager
        self.networkManager = networkManager
        self.upstreamDataSender = upstreamDataSender
        
        contextManager.add(provideContextDelegate: self)
        networkManager.add(statusDelegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        log.info("")
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
}

// MARK: - ContextInfoDelegate

extension SystemAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completionHandler: (ContextInfo?) -> Void) {
        let payload: [String: Any] = [
            "version": capabilityAgentProperty.version
        ]
        completionHandler(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload))
    }
}

// MARK: - NetworkStatusDelegate

extension SystemAgent: NetworkStatusDelegate {
    public func networkStatusDidChange(_ status: NetworkStatus) {
        switch status {
        case .connected:
            sendSynchronizeStateEvent()
        default:
            break
        }
    }
}

// MARK: - Private (handle directive)

private extension SystemAgent {
    func handleHandOffConnection() -> HandleDirective {
        return { [weak self] directive, completionHandler in
            completionHandler(
                Result { [weak self] in
                    guard let data = directive.payload.data(using: .utf8) else {
                        throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
                    }
                    
                    let serverPolicy = try JSONDecoder().decode(Policy.ServerPolicy.self, from: data)
                    self?.systemDispatchQueue.async { [weak self] in
                        // TODO: hand off는 이제 server-initiated directive를 받는 것에 한해서만 유용하다. 일단 삭제하고 network manager가 전이중방식으로 바뀌면 구현할 것.
                        log.info("try to handoff policy: \(serverPolicy)")
                        self?.networkManager.connect()
                    }
                }
            )
        }
    }
    
    func handleUpdateState() -> HandleDirective {
        return { [weak self] directive, completionHandler in
            self?.systemDispatchQueue.async { [weak self] in
                self?.sendSynchronizeStateEvent()
            }
            
            completionHandler(.success(()))
        }
        
    }
    
    func handleException() -> HandleDirective {
        return { [weak self] directive, completionHandler in
            completionHandler(
                Result { [weak self] in
                    guard let data = directive.payload.data(using: .utf8) else {
                        throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
                    }
                    
                    let exceptionItem = try JSONDecoder().decode(SystemAgentExceptionItem.self, from: data)
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
            )
        }
    }
}

private extension SystemAgent {
    func sendSynchronizeStateEvent() {
        contextManager.getContexts { [weak self] (contextPayload) in
            guard let self = self else { return }
            
            self.upstreamDataSender.send(
                upstreamEventMessage: Event(
                    typeInfo: .synchronizeState
                ).makeEventMessage(
                    agent: self,
                    contextPayload: contextPayload
                )
            )
        }
    }
}
