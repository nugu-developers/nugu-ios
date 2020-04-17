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
    
    private let textDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.text_agent", qos: .userInitiated)
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "TextSource", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleTextSource)
    ]
    
    public init(
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable,
        directiveSequencer: DirectiveSequenceable
    ) {
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
        self.directiveSequencer = directiveSequencer
        
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        contextManager.add(delegate: self)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - TextAgentProtocol

extension TextAgent {
    @discardableResult public func requestTextInput(text: String, completion: ((StreamDataState) -> Void)?) -> String {
        return sendTextInput(text: text, token: nil, completion: completion)
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
            defer { completion() }
        
            guard let payload = try? JSONDecoder().decode(TextAgentSourceItem.self, from: directive.payload) else {
                log.error("Invalid payload")
                return
            }
            
            self?.textDispatchQueue.async { [weak self] in
                self?.sendTextInput(
                    text: payload.text,
                    token: payload.token,
                    expectSpeech: nil,
                    directive: directive,
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
        expectSpeech: ASRExpectSpeech? = nil,
        directive: Downstream.Directive? = nil,
        completion: ((StreamDataState) -> Void)?
    ) -> String {
        let dialogRequestId = TimeUUID().hexString
        
        let expectSpeech = delegate?.textAgentDidRequestExpectSpeech()
        contextManager.getContexts { [weak self] contextPayload in
            guard let self = self else { return }
            
            self.upstreamDataSender.sendEvent(
                Event(
                    typeInfo: .textInput(text: text, token: token, expectSpeech: expectSpeech)
                ).makeEventMessage(
                    property: self.capabilityAgentProperty,
                    dialogRequestId: dialogRequestId,
                    referrerDialogRequestId: directive?.header.dialogRequestId,
                    contextPayload: contextPayload
                ),
                completion: completion
            )
        }
        return dialogRequestId
    }
}
