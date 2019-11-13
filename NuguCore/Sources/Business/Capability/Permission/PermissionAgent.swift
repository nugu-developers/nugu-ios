//
//  PermissionAgent.swift
//  NuguCore
//
//  Created by yonghoonKwon on 2019/11/12.
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

final public class PermissionAgent: PermissionAgentProtocol {
    public var capabilityAgentProperty = CapabilityAgentProperty(category: .permission, version: "1.0")
    
    public var messageSender: MessageSendable!
    
    public weak var delegate: PermissionAgentDelegate?
    
    public init() {
        log.info("")
    }
    
    deinit {
        log.info("")
    }
}

// MARK: - HandleDirectiveDelegate

extension PermissionAgent: HandleDirectiveDelegate {
    public func handleDirectiveTypeInfos() -> DirectiveTypeInfos {
        return DirectiveTypeInfo.allDictionaryCases
    }
    
    public func handleDirective(
        _ directive: DirectiveProtocol,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self) else {
            completionHandler(.failure(HandleDirectiveError.handleDirectiveError(message: "Unknown directive")))
            return
        }
        
        switch directiveTypeInfo {
        case .requestAccess:
            guard let data = directive.payload.data(using: .utf8) else {
                completionHandler(.failure(HandleDirectiveError.handleDirectiveError(message: "Invalid payload")))
                return
            }
            
            let item: PermissionAgentItem
            do {
                item = try JSONDecoder().decode(PermissionAgentItem.self, from: data)
            } catch {
                completionHandler(.failure(error))
                return
            }
            
            delegate?.permissionAgentRequestPermissions(categories: Set(item.permissions)) { [weak self] in
                guard let self = self else { return }
                self.sendEvent(
                    PermissionAgent.Event(typeInfo: .requestAccessCompleted),
                    context: self.contextInfoRequestContext(),
                    dialogRequestId: TimeUUID().hexString,
                    by: self.messageSender
                )
            }
            
            completionHandler(.success(()))
        }
    }
}

// MARK: - ContextInfoDelegate

extension PermissionAgent: ContextInfoDelegate {
    public func contextInfoRequestContext() -> ContextInfo? {
        var payload: [String: Any] = ["version": capabilityAgentProperty.version]
        let permissionContext = delegate?.permissionAgentRequestContext()
        
        if let permissions = permissionContext?.permissions {
            payload["permissions"] = permissions.map {
                return [
                    "name": $0.category.rawValue,
                    "state": $0.state.rawValue
                ]
            }
        }
        
        return ContextInfo(
            contextType: .capability,
            name: capabilityAgentProperty.name,
            payload: payload
        )
    }
}
