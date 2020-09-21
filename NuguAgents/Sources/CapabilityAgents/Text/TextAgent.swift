//
//  TextAgent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 17/06/2019.
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

import RxSwift

public final class TextAgent: TextAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .text, version: "1.1")
    
    public weak var delegate: TextAgentDelegate?
    
    // Private
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    private let directiveSequencer: DirectiveSequenceable
    private let dialogAttributeStore: DialogAttributeStoreable
    
    private let textDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.text_agent", qos: .userInitiated)
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "TextSource", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleTextSource)
    ]
    
    public init(
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable,
        directiveSequencer: DirectiveSequenceable,
        dialogAttributeStore: DialogAttributeStoreable
    ) {
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
        self.directiveSequencer = directiveSequencer
        self.dialogAttributeStore = dialogAttributeStore
        
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        contextManager.add(delegate: self)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - TextAgentProtocol

extension TextAgent {
    @discardableResult public func requestTextInput(
        text: String,
        token: String?,
        requestType: TextAgentRequestType,
        completion: ((StreamDataState) -> Void)?
    ) -> String {
        return sendTextInput(text: text, token: token, requestType: requestType, completion: completion)
    }
}

// MARK: - ContextInfoDelegate

extension TextAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: (ContextInfo?) -> Void) {
        let payload: [String: AnyHashable] = ["version": capabilityAgentProperty.version]        
        completion(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload))
    }
}

// MARK: - Private(Directive)

private extension TextAgent {
    func handleTextSource() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payload = try? JSONDecoder().decode(TextAgentSourceItem.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            
            self?.textDispatchQueue.async { [weak self] in
                
                let requestType: TextAgentRequestType
                if let playServiceId = payload.playServiceId {
                    requestType = .specific(playServiceId: playServiceId)
                } else {
                    requestType = .dialog
                }
                
                self?.sendTextInput(
                    text: payload.text,
                    token: payload.token,
                    requestType: requestType,
                    referrerDialogRequestId: directive.header.dialogRequestId,
                    completion: nil
                )
            }
        }
    }
}

// MARK: - Private(Event)

private extension TextAgent {
    @discardableResult func sendTextInput(
        text: String,
        token: String?,
        requestType: TextAgentRequestType,
        referrerDialogRequestId: String? = nil,
        completion: ((StreamDataState) -> Void)?
    ) -> String {
        let eventIdentifier = EventIdentifier()
        contextManager.getContexts { [weak self] contextPayload in
            guard let self = self else { return }
            
            let attributes: [String: AnyHashable]?
            switch requestType {
            case .specific(let playServiceId):
                attributes = ["playServiceId": playServiceId]
            case .dialog:
                attributes = self.dialogAttributeStore.attributes
            case .normal:
                attributes = nil
            }
            
            self.upstreamDataSender.sendEvent(
                Event(
                    typeInfo: .textInput(
                        text: text,
                        token: token,
                        attributes: attributes
                    )
                ).makeEventMessage(
                    property: self.capabilityAgentProperty,
                    eventIdentifier: eventIdentifier,
                    referrerDialogRequestId: referrerDialogRequestId,
                    contextPayload: contextPayload
                ),
                completion: completion)
        }
        return eventIdentifier.dialogRequestId
    }
}
