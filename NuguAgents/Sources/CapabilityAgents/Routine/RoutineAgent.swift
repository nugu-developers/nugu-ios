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
import NuguUtils

import RxSwift

public final class RoutineAgent: RoutineAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .routine, version: "1.3")
    
    // RoutineAgentProtocol
    public weak var delegate: RoutineAgentDelegate?
    
    public var state: RoutineState { routineExecuter.state }
    public var routineItem: RoutineItem? { routineExecuter.routine }
    
    public var interruptTimeoutInSeconds: Int? {
        get {
            routineExecuter.interruptTimeoutInSeconds
        } set {
            routineExecuter.interruptTimeoutInSeconds = newValue
        }
    }
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    private let routineExecuter: RoutineExecuter
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Start", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleStart),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Stop", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleStop),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Continue", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleContinue),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Move", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleMove)
    ]
    
    private var disposeBag = DisposeBag()
    
    public init(
        upstreamDataSender: UpstreamDataSendable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable,
        streamDataRouter: StreamDataRoutable,
        textAgent: TextAgentProtocol,
        asrAgent: ASRAgentProtocol
    ) {
        self.upstreamDataSender = upstreamDataSender
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        self.routineExecuter = RoutineExecuter(
            directiveSequencer: directiveSequencer,
            streamDataRouter: streamDataRouter,
            asrAgent: asrAgent,
            textAgent: textAgent
        )
        
        contextManager.addProvider(contextInfoProvider)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        routineExecuter.delegate = self
    }
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        let routine = self.routineExecuter.routine
        let actions = routine?.payload.actions.map { action -> [String: AnyHashable?] in
            [
                "type": action.type.rawValue,
                "text": action.text,
                "data": action.data,
                "playServiceId": action.playServiceId,
                "token": action.token,
                "postDelayInMilliseconds": action.postDelayInMilliseconds
            ]
        }.map { $0.compactMapValues { $0 } }
        
        let payload: [String: AnyHashable?] = [
            "version": self.capabilityAgentProperty.version,
            "token": routine?.payload.token,
            "name": routine?.payload.name,
            "routineId": routine?.payload.routineId,
            "routineType": routine?.payload.routineType?.rawValue,
            "routineListType": routine?.payload.routineListType?.rawValue,
            "routineActivity": self.routineExecuter.state.routineActivity,
            "currentAction": self.routineExecuter.routineActionIndex?.advanced(by: 1),
            "actions": actions
        ]
        
        completion(
            ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 })
        )
    }
    
    public func previous(completion: @escaping (Bool) -> Void) {
        guard let routine = routineExecuter.routine else {
            log.debug("routine is not exist")
            completion(false)
            return
        }
        sendCompactContextEvent(Event(
            typeInfo: .moveControl(offset: -1),
            playServiceId: routine.payload.playServiceId,
            referrerDialogRequestId: routine.dialogRequestId
        ).rx)
        completion(true)
    }
    
    public func next(completion: @escaping (Bool) -> Void) {
        guard let routine = routineExecuter.routine else {
            log.debug("routine is not exist")
            completion(false)
            return
        }
        sendCompactContextEvent(Event(
            typeInfo: .moveControl(offset: 1),
            playServiceId: routine.payload.playServiceId,
            referrerDialogRequestId: routine.dialogRequestId
        ).rx)
        completion(true)
    }
    
    public func pause() {
        routineExecuter.pause()
    }
    
    public func stop() {
        routineExecuter.stop()
        
        guard let routine = routineExecuter.routine else { return }
        sendCompactContextEvent(Event(
            typeInfo: .stopped,
            playServiceId: routine.payload.playServiceId,
            referrerDialogRequestId: routine.dialogRequestId
        ).rx)
    }
}

// MARK: - RoutineExecuterDelegate

extension RoutineAgent: RoutineExecuterDelegate {
    func routineExecuterDidChange(state: RoutineState) {
        guard let routine = routineExecuter.routine else { return }
        
        switch state {
        case .idle:
            break
        case .playing:
            sendCompactContextEvent(Event(
                typeInfo: .started,
                playServiceId: routine.payload.playServiceId,
                referrerDialogRequestId: routine.dialogRequestId
            ).rx)
        case .interrupted:
            break
        case .finished:
            sendCompactContextEvent(Event(
                typeInfo: .finished,
                playServiceId: routine.payload.playServiceId,
                referrerDialogRequestId: routine.dialogRequestId
            ).rx)
        case .stopped:
            sendCompactContextEvent(Event(
                typeInfo: .stopped,
                playServiceId: routine.payload.playServiceId,
                referrerDialogRequestId: routine.dialogRequestId
            ).rx)
        default:
            break
        }
        
        delegate?.routineAgentDidChange(state: state, item: routine)
    }
    
    func routineExecuterShouldSendActionTriggerTimout(token: String) {
        guard let routine = routineExecuter.routine else { return }
        sendCompactContextEvent(Event(
            typeInfo: .actionTimeoutTriggered(token: token),
            playServiceId: routine.payload.playServiceId,
            referrerDialogRequestId: routine.dialogRequestId
        ).rx)
    }
    
    func routineExecuterWillProcessAction(_ action: RoutineItem.Payload.Action) {
        delegate?.routineAgentWillProcessAction(action)
    }
    
    func routineExecuterShouldRequestAction(
        action: RoutineItem.Payload.Action,
        referrerDialogRequestId: String,
        completion: @escaping (StreamDataState) -> Void
    ) -> EventIdentifier {
        return sendCompactContextEvent(Event(
            typeInfo: .actionTriggered(data: action.data),
            playServiceId: action.playServiceId,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx, completion: completion)
    }
    
    func routineExecuterDidStopProcessingAction(_ action: RoutineItem.Payload.Action) {
        delegate?.routineAgentDidStopProcessingAction(action)
    }
    
    func routineExecuterDidFinishProcessingAction(_ action: RoutineItem.Payload.Action) {
        delegate?.routineAgentDidFinishProcessingAction(action)
    }
}

// MARK: - Private(Directive)

private extension RoutineAgent {
    func handleStart() -> HandleDirective {
        return { [weak self] directive, completion in
            log.debug("")
            guard let payload = try? JSONDecoder().decode(RoutineItem.Payload.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            
            let routine = RoutineItem(
                dialogRequestId: directive.header.dialogRequestId,
                messageId: directive.header.messageId,
                payload: payload
            )
            
            self?.routineExecuter.start(routine)
        }
    }
    
    func handleStop() -> HandleDirective {
        return { [weak self] directive, completion in
            log.debug("")
            guard let payloadDictionary = directive.payloadDictionary,
                  let token = payloadDictionary["token"] as? String else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            
            if self?.routineExecuter.routine?.payload.token == token {
                self?.routineExecuter.stop()
            }
        }
    }
    
    func handleContinue() -> HandleDirective {
        return { [weak self] directive, completion in
            log.debug("")
            guard let payloadDictionary = directive.payloadDictionary,
                  let token = payloadDictionary["token"] as? String,
                  let playServiceId = payloadDictionary["playServiceId"] as? String else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            
            guard self?.routineExecuter.routine?.payload.token == token else {
                self?.sendCompactContextEvent(Event(
                    typeInfo: .failed(errorCode: "Invalid request"),
                    playServiceId: playServiceId,
                    referrerDialogRequestId: directive.header.dialogRequestId
                ).rx)
                return
            }
            
            self?.routineExecuter.resume()
        }
    }
    
    func handleMove() -> HandleDirective {
        return { [weak self] directive, completion in
            log.debug("")
            guard let payloadDictionary = directive.payloadDictionary,
                  let token = payloadDictionary["token"] as? String,
                  let playServiceId = payloadDictionary["playServiceId"] as? String,
                  let position = payloadDictionary["position"] as? Int else {
                completion(.failed("Invalid payload"))
                return
            }
            
            guard self?.routineExecuter.routine?.payload.token == token else {
                self?.sendCompactContextEvent(Event(
                    typeInfo: .failed(errorCode: "Invalid request"),
                    playServiceId: playServiceId,
                    referrerDialogRequestId: directive.header.dialogRequestId
                ).rx)
                completion(.failed("Invalid request"))
                return
            }
            
            self?.routineExecuter.move(to: position - 1) { [weak self] isSuccess in
                log.debug("move to action \(position), result: \(isSuccess)")
                // TODO: - add error code
                let typeInfo: Event.TypeInfo = isSuccess ? .moveSucceeded : .moveFailed(errorCode: "")
                
                self?.sendCompactContextEvent(Event(
                    typeInfo: typeInfo,
                    playServiceId: playServiceId,
                    referrerDialogRequestId: directive.header.dialogRequestId
                ).rx)
            }
            
            completion(.finished)
        }
    }
}

// MARK: - Private (Event)

private extension RoutineAgent {
    @discardableResult func sendCompactContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(namespace: self.capabilityAgentProperty.name),
            property: self.capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
}
