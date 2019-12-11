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

final public class SystemAgent: SystemAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .system, version: "1.0")
    
    private let systemDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.system_agent", qos: .userInitiated)
    
    private let contextManager: ContextManageable
    private let networkManager: NetworkManageable
    
    private var serverPolicy: Policy.ServerPolicy?
    private var dialogState: DialogState = .idle
    
    private let delegates = DelegateSet<SystemAgentDelegate>()
    
    public init(
        contextManager: ContextManageable,
        networkManager: NetworkManageable
    ) {
        log.info("")
        
        self.contextManager = contextManager
        self.networkManager = networkManager
    }
    
    deinit {
        log.info("")
    }
}

// MARK: - HandleDirectiveDelegate

extension SystemAgent: HandleDirectiveDelegate {
    public func handleDirectiveTypeInfos() -> DirectiveTypeInfos {
        return DirectiveTypeInfo.allDictionaryCases
    }
    
    public func handleDirective(
        _ directive: DownStream.Directive,
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

// MARK: - DialogStateDelegate

extension SystemAgent: DialogStateDelegate {
    public func dialogStateDidChange(_ state: DialogState) {
        systemDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.dialogState = state
            self.connect()
        }
    }
}

// MARK: - Private (handle directive)

private extension SystemAgent {
    func handOffConnection(directive: DownStream.Directive) -> Result<Void, Error> {
        return Result { [weak self] in
            guard let data = directive.payload.data(using: .utf8) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
            }
            
            self?.serverPolicy = try JSONDecoder().decode(Policy.ServerPolicy.self, from: data)
            self?.systemDispatchQueue.async { [weak self] in
                self?.connect()
            }
        }
    }
    
    func updateState() -> Result<Void, Error> {
        systemDispatchQueue.async { [weak self] in
            self?.sendSynchronizeStateEvent()
        }
        
        return .success(())
    }
    
    func handleException(directive: DownStream.Directive) -> Result<Void, Error> {
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
                dialogRequestId: TimeUUID().hexString,
                by: self.networkManager
            )
        }
    }
    
    func connect() {
        // DialogState 가 idle 일 때 hand off
        guard case .idle = dialogState else { return }

        if let serverPolicy = serverPolicy,
            // TODO: casting 제거
            let networkManager = networkManager as? NetworkManager {
            self.serverPolicy = nil
            networkManager.connect(serverPolicies: [serverPolicy])
        }
    }
}
