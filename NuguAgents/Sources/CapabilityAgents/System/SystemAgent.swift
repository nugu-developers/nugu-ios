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
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "HandoffConnection", medium: .none, isBlocking: false, directiveHandler: handleHandOffConnection),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "UpdateState", medium: .none, isBlocking: false, directiveHandler: handleUpdateState),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Exception", medium: .none, isBlocking: false, directiveHandler: handleException),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Revoke", medium: .none, isBlocking: false, directiveHandler: handleRevoke),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "NoDirectives", medium: .none, isBlocking: false, directiveHandler: { { $1(.success(())) } }),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Noop", medium: .none, isBlocking: false, directiveHandler: { { $1(.success(())) } })
    ]
    
    public init(
        contextManager: ContextManageable,
        streamDataRouter: StreamDataRoutable,
        directiveSequencer: DirectiveSequenceable
    ) {
        self.contextManager = contextManager
        self.streamDataRouter = streamDataRouter
        self.directiveSequencer = directiveSequencer
        
        contextManager.add(provideContextDelegate: self)
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

// MARK: - NetworkStatusDelegate

// TODO: v2에서는 "네트워크가 연결되면"이라는 상태가 없음. 초기에 context를 전송하는 로직 수정해야 함.
//extension SystemAgent: NetworkStatusDelegate {
//    public func networkStatusDidChange(_ status: NetworkStatus) {
//        switch status {
//        case .connected:
//            sendSynchronizeStateEvent()
//        default:
//            break
//        }
//    }
//}

// MARK: - Private (handle directive)

private extension SystemAgent {
    func handleHandOffConnection() -> HandleDirective {
        return { [weak self] directive, completion in
            completion(
                Result { [weak self] in
                    guard let data = directive.payload.data(using: .utf8) else {
                        throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
                    }
                    
                    let serverPolicy = try JSONDecoder().decode(Policy.ServerPolicy.self, from: data)
                    self?.systemDispatchQueue.async { [weak self] in
                        // TODO: hand off는 이제 server-initiated directive를 받는 것에 한해서만 유용하다. 일단 삭제하고 network manager가 전이중방식으로 바뀌면 구현할 것.
                        log.info("try to handoff policy: \(serverPolicy)")
                        self?.streamDataRouter.handOffResourceServer(to: serverPolicy)
                    }
                }
            )
        }
    }
    
    func handleUpdateState() -> HandleDirective {
        return { [weak self] directive, completion in
            self?.systemDispatchQueue.async { [weak self] in
                self?.sendSynchronizeStateEvent()
            }
            
            completion(.success(()))
        }
        
    }
    
    func handleException() -> HandleDirective {
        return { [weak self] directive, completion in
            completion(
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
    
    func handleRevoke() -> HandleDirective {
        return { [weak self] _, completion in
            self?.systemDispatchQueue.async { [weak self] in
                self?.delegates.notify { delegate in
                    delegate.systemAgentDidReceiveRevokeDevice()
                }
            }
            completion(.success(()))
        }
    }
}

private extension SystemAgent {
    func sendSynchronizeStateEvent() {
        contextManager.getContexts { [weak self] (contextPayload) in
            guard let self = self else { return }
            
            self.streamDataRouter.sendEvent(
                Event(
                    typeInfo: .synchronizeState
                ).makeEventMessage(
                    agent: self,
                    contextPayload: contextPayload
                )
            )
        }
    }
}
