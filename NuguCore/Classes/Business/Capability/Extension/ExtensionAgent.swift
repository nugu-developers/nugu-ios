//
//  ExtensionAgent.swift
//  NuguCore
//
//  Created by yonghoonKwon on 25/07/2019.
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

final public class ExtensionAgent: ExtensionAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .extension, version: "1.0")
    
    public var messageSender: MessageSendable!
    
    public weak var delegate: ExtensionAgentDelegate?
    
    public init() {
        log.info("")
    }
    
    deinit {
        log.info("")
    }
}

// MARK: - HandleDirectiveDelegate

extension ExtensionAgent: HandleDirectiveDelegate {
    public func handleDirectiveTypeInfos() -> DirectiveTypeInfos {
        return DirectiveTypeInfo.allDictionaryCases
    }
    
    public func handleDirective(
        _ directive: DirectiveProtocol,
        completionHandler: @escaping (Result<Void, Error>) -> Void) {
        guard let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self) else {
            completionHandler(.failure(HandleDirectiveError.handleDirectiveError(message: "Unknown directive")))
            return
        }
        
        switch directiveTypeInfo {
        case .action:
            guard let data = directive.payload.data(using: .utf8) else {
                completionHandler(.failure(HandleDirectiveError.handleDirectiveError(message: "Invalid payload")))
                return
            }
            
            let item: ExtensionAgentItem
            do {
                item = try JSONDecoder().decode(ExtensionAgentItem.self, from: data)
            } catch {
                completionHandler(.failure(error))
                return
            }
            
            delegate?.extensionAgentDidReceiveAction(
                data: item.data,
                playServiceId: item.playServiceId,
                completion: { [weak self] (isSuccess) in
                    guard let self = self else { return }
                    
                    let eventTypeInfo: ExtensionAgent.Event.TypeInfo = isSuccess ? .actionSucceeded : .actionFailed
                    let event = ExtensionAgent.Event(playServiceId: item.playServiceId, typeInfo: eventTypeInfo)
                    
                    self.sendEvent(
                        event,
                        context: self.provideContext(),
                        dialogRequestId: TimeUUID().hexString,
                        by: self.messageSender
                    )
            })
            
            completionHandler(.success(()))
        }
    }
}

// MARK: - ProvideContextDelegate

extension ExtensionAgent: ProvideContextDelegate {
    public func provideContext() -> ContextInfo? {
        let payload: [String: Any?] = [
            "version": capabilityAgentProperty.version,
            "data": delegate?.extensionAgentRequestContext()
        ]
        
        return ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 })
    }
}
