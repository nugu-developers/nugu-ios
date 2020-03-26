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
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .text, version: "1.0")
    
    // Private
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    private let directiveSequencer: DirectiveSequenceable
    
    private let textDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.text_agent", qos: .userInitiated)
    
    private let delegates = DelegateSet<TextAgentDelegate>()
    
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
        contextManager.add(provideContextDelegate: self)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - TextAgentProtocol

extension TextAgent {
    public func add(delegate: TextAgentDelegate) {
        delegates.add(delegate)
    }
    
    public func remove(delegate: TextAgentDelegate) {
        delegates.remove(delegate)
    }
    
    public func requestTextInput(text: String, expectSpeech: ASRExpectSpeech?) {
        sendTextInput(text: text, token: nil, expectSpeech: expectSpeech)
    }
}

// MARK: - ContextInfoDelegate

extension TextAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: (ContextInfo?) -> Void) {
        let payload: [String: Any] = ["version": capabilityAgentProperty.version]        
        completion(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload))
    }
}

// MARK: - Private(Directive)

private extension TextAgent {
    func handleTextSource() -> HandleDirective {
        return { [weak self] directive, completion in
            self?.textDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                let result = Result<Void, Error> {
                    guard let data = directive.payload.data(using: .utf8) else {
                        throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
                    }
                    let payload = try JSONDecoder().decode(TextAgentSourceItem.self, from: data)
                    
                    self.sendTextInput(text: payload.text, token: payload.token, expectSpeech: nil)
                }
                
                completion(result)
            }
        }
    }
}

// MARK: - Private(Event)

private extension TextAgent {
    func sendTextInput(text: String, token: String?, expectSpeech: ASRExpectSpeech?) {
        textDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.contextManager.getContexts { (contextPayload) in
                let textRequest = TextRequest(
                    contextPayload: contextPayload,
                    text: text,
                    dialogRequestId: TimeUUID().hexString,
                    token: token,
                    expectSpeech: expectSpeech
                )
                
                self.upstreamDataSender.sendEvent(
                    Event(
                        typeInfo: .textInput(
                            text: textRequest.text,
                            expectSpeech: textRequest.expectSpeech
                        )
                    ).makeEventMessage(agent: self)) { [weak self] state in
                        guard let self = self else { return }

                        self.delegates.notify({ (delegate) in
                            delegate.textAgentDidStreamStateChanged(state: state, dialogRequestId: textRequest.dialogRequestId)
                        })
                }
            }
        }
    }
}
