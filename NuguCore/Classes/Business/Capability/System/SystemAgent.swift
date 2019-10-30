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
    
    public var contextManager: ContextManageable!
    public var networkManager: NetworkManageable!
    
    private var serverPolicy: Policy.ServerPolicy?
    private var dialogState: DialogState = .idle
    
    private let delegates = DelegateSet<SystemAgentDelegate>()
    
    public init() {}
}

// MARK: - HandleDirectiveDelegate

extension SystemAgent: HandleDirectiveDelegate {
    public func handleDirectiveTypeInfos() -> DirectiveTypeInfos {
        return DirectiveTypeInfo.allDictionaryCases
    }
    
    public func handleDirective(
        _ directive: DirectiveProtocol,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        let result = Result<DirectiveTypeInfo, Error>(catching: {
            guard let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Unknown directive")
            }
            
            return directiveTypeInfo
        }).flatMap ({ (typeInfo) -> Result<Void, Error> in
            switch typeInfo {
            case .handOffConnection:
                return handOffConnection(directive: directive)
            case .updateState:
                return updateState()
            case .exception:
                return handleException(directive: directive)
            case .noDirectives:
                // do nothing
                return .success(())
            case .revoke:
                return revoke(directive: directive)
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

// MARK: - ProvideContextDelegate

extension SystemAgent: ProvideContextDelegate {
    public func provideContext() -> ContextInfo? {
        let payload: [String: Any] = [
            "version": capabilityAgentProperty.version,
            "battery": Int(Double(UIDevice.current.batteryLevel) * 100)
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
    func handOffConnection(directive: DirectiveProtocol) -> Result<Void, Error> {
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
    
    func handleException(directive: DirectiveProtocol) -> Result<Void, Error> {
        return Result { [weak self] in
            guard let data = directive.payload.data(using: .utf8) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
            }
            
            let exceptionItem = try JSONDecoder().decode(SystemAgentExceptionItem.self, from: data)
            self?.systemDispatchQueue.async { [weak self] in
                switch exceptionItem.code {
                case .unauthorizedRequestException:
                    self?.delegates.notify { delegate in
                        delegate.systemAgentDidReceiveAuthorizationError()
                    }
                default:
                    break
                }
            }
        }
    }
    
    func revoke(directive: DirectiveProtocol) -> Result<Void, Error> {
        return Result { [weak self] in
            guard let data = directive.payload.data(using: .utf8) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
            }
            
            let revokeItem = try JSONDecoder().decode(SystemAgentRevokeItem.self, from: data)
            self?.systemDispatchQueue.async { [weak self] in
                self?.delegates.notify { delegate in
                    delegate.systemAgentDidReceiveRevoke(reason: revokeItem.reason)
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
