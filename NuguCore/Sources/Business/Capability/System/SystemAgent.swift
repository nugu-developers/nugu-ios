//
//  SystemAgent.swift
//  NuguCore
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

import NuguInterface

final public class SystemAgent: SystemAgentProtocol, CapabilityDirectiveAgentable, CapabilityEventAgentable {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .system, version: "1.0")
    
    // CapabilityEventAgentable
    public let upstreamDataSender: UpstreamDataSendable
    
    // Private
    private let contextManager: ContextManageable
    private let networkManager: NetworkManageable
    
    private let systemDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.system_agent", qos: .userInitiated)
    
    private var serverPolicy: Policy.ServerPolicy?
    
    private let delegates = DelegateSet<SystemAgentDelegate>()
    
    public init(
        contextManager: ContextManageable,
        networkManager: NetworkManageable,
        upstreamDataSender: UpstreamDataSendable,
        directiveSequencer: DirectiveSequenceable,
        authorizationManager: AuthorizationManageable
    ) {
        log.info("")
        
        self.contextManager = contextManager
        self.networkManager = networkManager
        self.upstreamDataSender = upstreamDataSender
        
        self.add(systemAgentDelegate: authorizationManager)
        
        contextManager.add(provideContextDelegate: self)
        networkManager.add(statusDelegate: self)
        directiveSequencer.add(handleDirectiveDelegate: self)
    }
    
    deinit {
        log.info("")
    }
}

// MARK: - HandleDirectiveDelegate

extension SystemAgent: HandleDirectiveDelegate {
    public func handleDirective(
        _ directive: Downstream.Directive,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        let result = Result<DirectiveTypeInfo, Error>(catching: {
            guard let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Unknown directive")
            }
            
            return directiveTypeInfo
        }).flatMap({ (typeInfo) -> Result<Void, Error> in
            switch typeInfo {
            case .handoffConnection:
                return handOffConnection(directive: directive)
            case .updateState:
                return updateState()
            case .exception:
                return handleException(directive: directive)
            case .noDirectives:
                // do nothing
                return .success(())
            }
        })
        
        completionHandler(result)
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
    public func contextInfoRequestContext() -> ContextInfo? {
        let payload: [String: Any] = [
            "version": capabilityAgentProperty.version
        ]
        
        return ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload)
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
    func handOffConnection(directive: Downstream.Directive) -> Result<Void, Error> {
        return Result { [weak self] in
            guard let data = directive.payload.data(using: .utf8) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
            }
            
            let serverPolicy = try JSONDecoder().decode(Policy.ServerPolicy.self, from: data)
            self?.systemDispatchQueue.async { [weak self] in
                 // TODO: casting 제거
                if let networkManager = self?.networkManager as? NetworkManager {
                    networkManager.connect(serverPolicies: [serverPolicy])
                }
            }
        }
    }
    
    func updateState() -> Result<Void, Error> {
        systemDispatchQueue.async { [weak self] in
            self?.sendSynchronizeStateEvent()
        }
        
        return .success(())
    }
    
    func handleException(directive: Downstream.Directive) -> Result<Void, Error> {
        return Result { [weak self] in
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
    }
}

private extension SystemAgent {
    func sendSynchronizeStateEvent() {
        contextManager.getContexts { [weak self] (contextPayload) in
            guard let self = self else { return }
            
            self.sendEvent(
                Event(typeInfo: .synchronizeState),
                contextPayload: contextPayload,
                dialogRequestId: TimeUUID().hexString
            )
        }
    }
}
