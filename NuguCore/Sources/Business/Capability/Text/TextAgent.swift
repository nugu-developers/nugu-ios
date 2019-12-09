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

final public class TextAgent: TextAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .text, version: "1.0")
    
    private let textDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.text_agent", qos: .userInitiated)
    
    public var contextManager: ContextManageable!
    public var messageSender: MessageSendable!
    public var focusManager: FocusManageable!
    public var channel: FocusChannelConfigurable!
    public var dialogStateAggregator: DialogStateAggregatable!
    
    private let delegates = DelegateSet<TextAgentDelegate>()
    
    private var focusState: FocusState = .nothing
    private var textAgentState: TextAgentState = .idle {
        didSet {
            log.info("from: \(oldValue) to: \(textAgentState)")
            guard oldValue != textAgentState else { return }
            
            // dispose responseTimeout
            switch textAgentState {
            case .busy:
                break
            default:
                responseTimeout?.dispose()
            }
            
            delegates.notify { delegate in
                delegate.textAgentDidChange(state: textAgentState)
            }
        }
    }
    
    // For Recognize Event
    private var textRequest: TextRequest?
    
    private lazy var disposeBag = DisposeBag()
    private var responseTimeout: Disposable?
    
    public init() {
        log.info("")
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
    
    public func requestTextInput(text: String) {
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
                    dialogRequestId: TimeUUID().hexString
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
    public func focusChannelConfiguration() -> FocusChannelConfigurable {
        return channel
    }
    
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
            case (.background, _):
                self.releaseFocus()
            case (.nothing, _):
                self.textAgentState = .idle
            }
        }
    }
}

// MARK: - Private(FocusManager)

private extension TextAgent {
    func releaseFocus() {
        guard focusState != .nothing else { return }
        
        textRequest = nil
        focusManager.releaseFocus(channelDelegate: self)
    }
}

// MARK: - DownStreamDataDelegate

extension TextAgent: DownStreamDataDelegate {
    public func downStreamDataDidReceive(directive: DownStream.Directive) {
        textDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let request = self.textRequest else { return }
            guard request.dialogRequestId == directive.header.dialogRequestId else { return }
            
            switch self.textAgentState {
            case .busy:
                self.delegates.notify({ (delegate) in
                    delegate.textAgentDidReceive(result: .complete, dialogRequestId: request.dialogRequestId)
                })
                self.releaseFocus()
            case .idle:
                return
            }
        }
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
        
        responseTimeout?.dispose()
        responseTimeout = Observable<Int>
            .timer(NuguConfiguration.asrResponseTimeout, scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.releaseFocus()
                
                self.delegates.notify({ (delegate) in
                    delegate.textAgentDidReceive(result: .error(.responseTimeout), dialogRequestId: textRequest.dialogRequestId)
                })
            })
        responseTimeout?.disposed(by: disposeBag)
        
        sendEvent(
            Event(typeInfo: .textInput(text: textRequest.text), expectSpeech: dialogStateAggregator.expectSpeech),
            contextPayload: textRequest.contextPayload,
            dialogRequestId: textRequest.dialogRequestId,
            by: messageSender
        )
    }
}
