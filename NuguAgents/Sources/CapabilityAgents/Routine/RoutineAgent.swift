//
//  RoutineAgent.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/07/07.
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

final class RoutineAgent: RoutineAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .extension, version: "1.0")
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    private let routineDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.routine_agent", qos: .userInitiated)
    
    private var state: RoutineState = .idle {
        didSet {
            guard let item = currentItem else { return }
            
            switch state {
            case .idle:
                break
            case .playing:
                handlingDirectives = [Downstream.Directive]()
                sendEvent(typeInfo: .started, playServiceId: item.playServiceId)
                requestNextAction(index: 0)
            case .interrupt:
                break
            case .finished:
                sendEvent(typeInfo: .finished, playServiceId: item.playServiceId)
            case .stopped:
                sendEvent(typeInfo: .stopped, playServiceId: item.playServiceId)
            case .failed(let errorCode):
                sendEvent(typeInfo: .failed(errorCode: errorCode), playServiceId: item.playServiceId)
            }
        }
    }
    
    private var currentItem: RoutineStartPlayload?
    private var currentIndex: Int = 0
    private var handlingDirectives = [Downstream.Directive]()
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Start", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleStart),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Stop", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleStop),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Continue", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleContinue)
    ]
    
    public init(
        upstreamDataSender: UpstreamDataSendable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        self.upstreamDataSender = upstreamDataSender
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        
        contextManager.add(delegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        directiveSequencer.add(delegate: self)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - ContextInfoDelegate

extension RoutineAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: (ContextInfo?) -> Void) {
        let actions = currentItem?.actions.map { action -> [String: AnyHashable?] in
            [
                "type": action.type.rawValue,
                "text": action.text,
                "data": action.data,
                "playServiceId": action.playServiceId
            ]
        }.map { $0.compactMapValues { $0 } }
        let payload: [String: AnyHashable?] = [
            "version": capabilityAgentProperty.version,
            "token": currentItem?.token,
            "routineActivity": state.routineActivity,
            "currentAction": currentIndex + 1,
            "actions": actions
        ]
        
        completion(
            ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 })
        )
    }
}

// MARK: - DirectiveSequencerDelegate

extension RoutineAgent: DirectiveSequencerDelegate {
    func directiveSequencerDidHandle(directive: Downstream.Directive, result: DirectiveHandleResult) {
        routineDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.handlingDirectives.removeAll { $0.header.messageId == directive.header.messageId }
            switch result {
            case .failed:
                self.state = .failed("Handle directive failed")
            case .stopped:
                self.state = .interrupt
            case .completed:
                if self.handlingDirectives.contains(where: { $0.header.dialogRequestId == directive.header.dialogRequestId }) == false {
                    self.requestNextAction(index: self.currentIndex + 1)
                }
            }
        }
    }
}

// MARK: - Private(Directive)

private extension RoutineAgent {
    func handleStart() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
            
            guard let item = try? JSONDecoder().decode(RoutineStartPlayload.self, from: directive.payload) else {
                log.error("Invalid payload")
                return
            }
            
            self?.routineDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                self.currentItem = item
                self.state = .playing
            }
        }
    }
    
    func handleStop() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
            
            guard let payloadDictionary = directive.payloadDictionary,
                let token = payloadDictionary["token"] as? String else {
                    log.error("Invalid payload")
                    return
            }
            
            self?.routineDispatchQueue.async { [weak self] in
                if self?.currentItem?.token == token {
                    self?.state = .stopped
                }
            }
        }
    }
    
    func handleContinue() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
            
            guard let payloadDictionary = directive.payloadDictionary,
                let token = payloadDictionary["token"] as? String else {
                    log.error("Invalid payload")
                    return
            }
            
            self?.routineDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                if self.currentItem?.token == token {
                    self.requestNextAction(index: self.currentIndex + 1)
                }
            }
        }
    }
}

// MARK: - Private (Event)

private extension RoutineAgent {
    func sendEvent(
        typeInfo: Event.TypeInfo,
        playServiceId: String,
        dialogRequestId: String = TimeUUID().hexString,
        referrerDialogRequestId: String? = nil,
        completion: ((StreamDataState) -> Void)? = nil
    ) {
        contextManager.getContexts(namespace: capabilityAgentProperty.name) { [weak self] contextPayload in
            guard let self = self else { return }
            
            self.upstreamDataSender.sendEvent(
                Event(
                    playServiceId: playServiceId,
                    typeInfo: typeInfo
                ).makeEventMessage(
                    property: self.capabilityAgentProperty,
                    dialogRequestId: dialogRequestId,
                    referrerDialogRequestId: referrerDialogRequestId,
                    contextPayload: contextPayload
                ),
                completion: completion
            )
        }
    }
    
    func sendTextInputEvent(
        text: String,
        playServiceId: String?,
        dialogRequestId: String = TimeUUID().hexString,
        referrerDialogRequestId: String? = nil,
        completion: ((StreamDataState) -> Void)? = nil
    ) {
        contextManager.getContexts(namespace: capabilityAgentProperty.name) { [weak self] contextPayload in
            guard let self = self else { return }

            let header = Upstream.Event.Header(
                namespace: "Text",
                name: "TextInput",
                version: "1.1",
                dialogRequestId: dialogRequestId,
                messageId: TimeUUID().hexString,
                referrerDialogRequestId: referrerDialogRequestId
            )
            
            let payload = [
                "text": text,
                "playServiceId": playServiceId
            ]
            
            self.upstreamDataSender.sendEvent(
                Upstream.Event(
                    payload: payload.compactMapValues { $0 },
                    header: header,
                    contextPayload: contextPayload
                ),
                completion: completion
            )
        }
    }
}

// MARK: - Private

private extension RoutineAgent {
    func requestNextAction(index: Int) {
        guard let item = currentItem else { return }
        guard index < item.actions.count else {
            state = .finished
            return
        }
        
        self.currentIndex = index
        let action = item.actions[index]
        let completion: ((StreamDataState) -> Void) = { [weak self] result in
            self?.routineDispatchQueue.async { [weak self] in
                switch result {
                case .received(let directive):
                    self?.addHandlingDirective(directive: directive)
                case .error(let error):
                    self?.state = .failed("Request action failed \(error)")
                default:
                    break
                }
            }
        }
        switch action.type {
        case .text:
            guard let text = action.text else {
                state = .failed("actions.text is null")
                return
            }
            sendTextInputEvent(text: text, playServiceId: action.playServiceId, completion: completion)
        case .data:
            guard let data = action.data else {
                state = .failed("actions.data is null")
                return
            }
            guard let playServiceId = action.playServiceId else {
                state = .failed("actions.playServiceId is null")
                return
            }
            sendEvent(typeInfo: .actionTriggered(data: data), playServiceId: playServiceId, completion: completion)
        }
    }
    
    func addHandlingDirective(directive: Downstream.Directive) {
        handlingDirectives.append(directive)
    }
}
