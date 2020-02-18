//
//  ExtensionAgent.swift
//  NuguAgents
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

import NuguCore

final public class ExtensionAgent: ExtensionAgentProtocol, CapabilityEventAgentable {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .extension, version: "1.1")
    
    // CapabilityEventAgentable
    public let upstreamDataSender: UpstreamDataSendable
    
    // ExtensionAgentProtocol
    public weak var delegate: ExtensionAgentDelegate?
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: "Extension", name: "Action", medium: .none, isBlocking: false, handler: handleAction)
    ]
    
    public init(
        upstreamDataSender: UpstreamDataSendable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        log.info("initiated")
        
        self.upstreamDataSender = upstreamDataSender
        self.directiveSequencer = directiveSequencer
        
        contextManager.add(provideContextDelegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        log.info("")
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - ExtensionAgentProtocol

public extension ExtensionAgent {
    func requestCommand(playServiceId: String, data: [String: Any], completion: ((Result<Void, Error>) -> Void)?) {
        let event = ExtensionAgent.Event(playServiceId: playServiceId, typeInfo: .commandIssued(data: data))
        self.sendEvent(event, dialogRequestId: TimeUUID().hexString, messageId: TimeUUID().hexString) { result in
            let result = result.map { _ in () }
            completion?(result)
        }
    }
}

// MARK: - ContextInfoDelegate

extension ExtensionAgent: ContextInfoDelegate {
    public func contextInfoRequestContext() -> ContextInfo? {
        let payload: [String: Any?] = [
            "version": capabilityAgentProperty.version,
            "data": delegate?.extensionAgentRequestContext()
        ]
        
        return ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 })
    }
}

// MARK: - Private(Directive)

private extension ExtensionAgent {
    func handleAction() -> HandleDirective {
        return { [weak self] directive, completionHandler in
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
            
            self?.delegate?.extensionAgentDidReceiveAction(
                data: item.data,
                playServiceId: item.playServiceId,
                completion: { [weak self] (isSuccess) in
                    guard let self = self else { return }
                    
                    let eventTypeInfo: ExtensionAgent.Event.TypeInfo = isSuccess ? .actionSucceeded : .actionFailed
                    let event = ExtensionAgent.Event(playServiceId: item.playServiceId, typeInfo: eventTypeInfo)
                    
                    self.sendEvent(
                        event,
                        dialogRequestId: TimeUUID().hexString,
                        messageId: TimeUUID().hexString
                    )
            })
            
            completionHandler(.success(()))
        }
    }
}
