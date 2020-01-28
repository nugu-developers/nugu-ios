//
//  TextAgent.swift
//  NuguCore
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

import NuguInterface

import RxSwift

final public class TextAgent: TextAgentProtocol, CapabilityEventAgentable, CapabilityFocusAgentable {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .text, version: "1.0")
    
    // CapabilityEventAgentable
    public let upstreamDataSender: UpstreamDataSendable
    
    // CapabilityFocusAgentable
    public let focusManager: FocusManageable
    public let channelPriority: FocusChannelPriority
    
    // Private
    private let contextManager: ContextManageable
    
    private let textDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.text_agent", qos: .userInitiated)
    
    private let delegates = DelegateSet<TextAgentDelegate>()
    
    private var focusState: FocusState = .nothing
    private var textAgentState: TextAgentState = .idle {
        didSet {
            log.info("from: \(oldValue) to: \(textAgentState)")
            guard oldValue != textAgentState else { return }
            
            // release textRequest
            if textAgentState == .idle {
                textRequest = nil
                releaseFocusIfNeeded()
            }
            
            delegates.notify { delegate in
                delegate.textAgentDidChange(state: textAgentState)
            }
        }
    }
    
    // For Recognize Event
    private var textRequest: TextRequest?
    
    public init(
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable,
        focusManager: FocusManageable,
        channelPriority: FocusChannelPriority
    ) {
        log.info("")
        
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
        self.focusManager = focusManager
        self.channelPriority = channelPriority
        
        contextManager.add(provideContextDelegate: self)
        focusManager.add(channelDelegate: self)
    }
    
    deinit {
        log.info("")
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
        textDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard self.textAgentState != .busy else {
                log.warning("Not permitted in current state \(self.textAgentState)")
                return
            }
            
            self.contextManager.getContexts { (contextPayload) in
                self.textRequest = TextRequest(
                    contextPayload: contextPayload,
                    text: text,
                    dialogRequestId: TimeUUID().hexString,
                    expectSpeech: expectSpeech
                )
                
                self.focusManager.requestFocus(channelDelegate: self)
            }
        }
    }
}

// MARK: - ContextInfoDelegate

extension TextAgent: ContextInfoDelegate {
    public func contextInfoRequestContext() -> ContextInfo? {
        let payload: [String: Any] = ["version": capabilityAgentProperty.version]
        
        return ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload)
    }
}

// MARK: - FocusChannelDelegate

extension TextAgent: FocusChannelDelegate {
    public func focusChannelDidChange(focusState: FocusState) {
        log.info("\(focusState) \(textAgentState)")
        self.focusState = focusState
        
        textDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch (focusState, self.textAgentState) {
            case (.foreground, .idle):
                self.sendRecognize()
            // Busy 무시
            case (.foreground, _):
                break
            // Background 허용 안함.
            case (_, let textAgentState) where textAgentState != .idle:
                self.textAgentState = .idle
            default:
                break
            }
        }
    }
}

// MARK: - Private(FocusManager)

private extension TextAgent {
    func releaseFocusIfNeeded() {
        guard focusState != .nothing else { return }
        guard textAgentState == .idle else {
            log.info("Not permitted in current state, \(textAgentState)")
            return
        }
        
        focusManager.releaseFocus(channelDelegate: self)
    }
}

// MARK: - Private(Event)

private extension TextAgent {
    func sendRecognize() {
        guard let textRequest = textRequest else {
            log.warning("TextRequest not exist")
            return
        }
        
        textAgentState = .busy
        
        sendEvent(
            Event(typeInfo: .textInput(text: textRequest.text, expectSpeech: textRequest.expectSpeech)),
            dialogRequestId: textRequest.dialogRequestId,
            messageId: TimeUUID().hexString
        ) { [weak self] result in
            guard let self = self else { return }
            guard textRequest.dialogRequestId == self.textRequest?.dialogRequestId else { return }
            
            let result = result.map { _ in () }
            self.delegates.notify({ (delegate) in
                delegate.textAgentDidReceive(result: result, dialogRequestId: textRequest.dialogRequestId)
            })
            self.textAgentState = .idle
        }
    }
}
