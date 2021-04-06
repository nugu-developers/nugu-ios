//
//  RoutineExecuter.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/10/12.
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

protocol RoutineExecuterDelegate: class {
    func routineExecuterDidStart(routine: RoutineItem)

    func routineExecuterShouldRequestAction(
        action: RoutineItem.Payload.Action,
        referrerDialogRequestId: String,
        completion: @escaping (StreamDataState) -> Void
    ) -> EventIdentifier

    func routineExecuterDidInterrupt(routine: RoutineItem)

    func routineExecuterDidStop(routine: RoutineItem)

    func routineExecuterDidFinish(routine: RoutineItem)
}

class RoutineExecuter {
    weak var delegate: RoutineExecuterDelegate?
    var routine: RoutineItem?
    var routineActionIndex: Int? {
        guard currentActionIndex >= 0 else { return nil }
        
        return currentActionIndex
    }
    var state: RoutineState = .idle {
        didSet {
            log.debug(state)
            
            interruptTimer?.cancel()
            switch state {
            case .idle:
                break
            case .playing:
                break
            case .interrupted:
                if hasNextAction {
                    actionWorkItem?.cancel()
                    if let dialogRequestId = handlingEvent {
                        directiveSequencer.cancelDirective(dialogRequestId: dialogRequestId)
                    }
                    // Interrupt 이후 60초 이내에 Routine.Continue directive 를 받지 못하면 Routine 종료.
                    let item = DispatchWorkItem { [weak self] in
                        guard let self = self, self.state == .interrupted else { return }
                        
                        self.doStop()
                    }
                    self.interruptTimer = item
                    routineDispatchQueue.asyncAfter(deadline: .now() + 60, execute: item)
                } else {
                    state = .stopped
                }
            case .finished:
                clear()
            case .stopped:
                clear()
            }
        }
    }

    private let directiveSequencer: DirectiveSequenceable
    private let textAgent: TextAgentProtocol

    private let stopTargets = ["AudioPlayer.Play", "ASR.ExpectSpeech"]
    private let interruptTargets = ["Text.TextInput", "ASR.Recognize"]

    private let routineDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.routine_executer")

    // Notification
    private var notificationTokens = [Any]()

    private var handlingDirectives = Set<String>()
    private var handlingEvent: String?
    private var interruptEvent: String?
    private var actionWorkItem: DispatchWorkItem?
    private var interruptTimer: DispatchWorkItem?
    
    private var currentActionIndex = -1
    
    init(
        directiveSequencer: DirectiveSequenceable,
        streamDataRouter: StreamDataRoutable,
        asrAgent: ASRAgentProtocol,
        textAgent: TextAgentProtocol
    ) {
        self.directiveSequencer = directiveSequencer
        self.textAgent = textAgent

        addStreamDataObserver(streamDataRouter)
        addAsrAgentObserver(asrAgent)
        addDirectiveSequencerObserver(directiveSequencer)
    }

    deinit {
        notificationTokens.forEach(NotificationCenter.default.removeObserver)
        notificationTokens.removeAll()
    }

    func start(_ routine: RoutineItem) {
        routineDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            log.debug(routine.payload.actions)
            self.clear()

            self.routine = routine
            self.currentActionIndex = 0
            self.state = .playing
            self.delegate?.routineExecuterDidStart(routine: routine)

            self.doAction()
        }
    }

    func stop() {
        routineDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            log.debug("")
            self.doStop()
        }
    }

    func resume() {
        routineDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            log.debug(self.state)
            if self.state == .interrupted {
                self.state = .playing
                self.doNextAction()
            }
        }
    }
}

// MARK: - Notification
private extension RoutineExecuter {
    func addDirectiveSequencerObserver(_ directiveSequencer: DirectiveSequenceable) {
        let token = directiveSequencer.observe(NuguCoreNotification.DirectiveSquencer.Complete.self, queue: routineDispatchQueue) { [weak self] (notification) in
            guard let self = self, self.routine != nil,
                  self.handlingDirectives.remove(notification.directive.header.messageId) != nil else { return }
            
//            if self.handlingDirectives.isEmpty {
//                log.debug("")
//                self.handlingEvent = nil
//            }
            
            log.debug(notification.result)
            switch notification.result {
            case .canceled:
                self.doStop()
            case .stopped(let policy):
                if policy.cancelAll {
                    self.doStop()
                } else {
                    self.doInterrupt()
                }
            case .failed, .finished:
                if self.handlingDirectives.isEmpty {
                    self.doNextAction()
                }
            }
        }
        notificationTokens.append(token)
    }

    func addAsrAgentObserver(_ asrAgent: ASRAgentProtocol) {
        let token = asrAgent.observe(NuguAgentNotification.ASR.StartRecognition.self, queue: routineDispatchQueue) { [weak self] (notification) in
            guard let self = self, self.routine != nil else { return }
            
            if self.doInterrupt() == true {
                log.debug("")
                self.interruptEvent = notification.dialogRequestId
            }
        }
        notificationTokens.append(token)
    }

    func addStreamDataObserver(_ streamDataRouter: StreamDataRoutable) {
        let directivesToken = streamDataRouter.observe(NuguCoreNotification.StreamDataRoute.ReceivedDirectives.self, queue: routineDispatchQueue) { [weak self] (notification) in
            guard let self = self, self.routine != nil else { return }
            
            // Directive 에 Routine 중단 대상이 포함되어 있으며, 다음 Action 이 있으면 Routine 종료
            if notification.directives.contains(where: { (directive) -> Bool in
                self.stopTargets.contains(directive.header.type)
            }), self.hasNextAction {
                log.debug("")
                self.doStop()
            }
            // Interrupt 상태에서 Routine 이 아닌 directive 가 전달될 경우 Routine 종료
            else if self.interruptEvent == notification.directives.first?.header.dialogRequestId,
                      notification.directives.contains(where: { (directive) -> Bool in
                        directive.header.namespace != CapabilityAgentCategory.routine.name
                      }) {
                log.debug("")
                self.doStop()
            }
            // Action 의 응답 directives 가 모두 실행완료 되면 다음 Action 을 실행하기 위해 저장
            else if self.handlingEvent == notification.directives.first?.header.dialogRequestId {
                log.debug("")
                notification.directives.map { $0.header.messageId }.forEach { self.handlingDirectives.insert($0) }
            }
        }
        notificationTokens.append(directivesToken)

        let eventTokens = streamDataRouter.observe(NuguCoreNotification.StreamDataRoute.ToBeSentEvent.self, queue: routineDispatchQueue) { [weak self] (notification) in
            guard let self = self, self.routine != nil else { return }
            
            // Action 에 의한 event
            if self.interruptTargets.contains(notification.event.header.type), self.handlingEvent != notification.event.header.dialogRequestId {
                if self.doInterrupt() == true {
                    log.debug("")
                    self.interruptEvent = notification.event.header.dialogRequestId
                }
            }
        }
        notificationTokens.append(eventTokens)
    }
}

// MARK: - Private

private extension RoutineExecuter {
    func doAction() {
        guard let routine = routine, state == .playing else { return }
        guard let action = currentAction else { return }
        
        let completion: ((StreamDataState) -> Void) = { [weak self] result in
            log.debug(result)
            if case .error = result {
                self?.doNextAction()
            }
        }
        
        log.debug(action.actionType)
        switch action.actionType {
        case .text:
            guard let text = action.text else {
                doNextAction()
                return
            }
            if let playServiceId = action.playServiceId {
                handlingEvent = textAgent.requestTextInput(text: text, token: action.token, requestType: .specific(playServiceId: playServiceId), completion: completion)

            } else {
                handlingEvent = textAgent.requestTextInput(text: text, token: action.token, requestType: .normal, completion: completion)
            }
        case .data:
            if let eventIdentifier = delegate?.routineExecuterShouldRequestAction(action: action, referrerDialogRequestId: routine.dialogRequestId, completion: completion) {
                handlingEvent = eventIdentifier.dialogRequestId
            }
        case .none:
            doNextAction()
        }
    }

    func doNextAction() {
        guard hasNextAction else {
            doFinish()
            return
        }
        
        actionWorkItem?.cancel()
        if let delay = currentAction?.postDelay {
            log.debug(delay)
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }

                self.currentActionIndex += 1
                self.doAction()
            }
            actionWorkItem = workItem
            routineDispatchQueue.asyncAfter(deadline: .now() + delay.dispatchTimeInterval, execute: workItem)
        } else {
            log.debug("")
            self.currentActionIndex += 1
            self.doAction()
        }
    }

    @discardableResult
    func doInterrupt() -> Bool {
        guard let routine = routine else { return false }
        guard state == .playing else { return false }
        
        log.debug("")
        state = .interrupted
        delegate?.routineExecuterDidInterrupt(routine: routine)

        return true
    }
    
    func doStop() {
        guard let routine = routine else { return }
        guard [.playing, .interrupted].contains(state) else { return }
        
        log.debug("")
        state = .stopped
        delegate?.routineExecuterDidStop(routine: routine)
    }

    func doFinish() {
        guard let routine = routine else { return }
        guard state == .playing else { return }
        
        log.debug("")
        state = .finished
        delegate?.routineExecuterDidFinish(routine: routine)
    }

    func clear() {
        log.debug("")
        if let dialogRequestId = handlingEvent {
            directiveSequencer.cancelDirective(dialogRequestId: dialogRequestId)
        }

        handlingDirectives.removeAll()
        handlingEvent = nil
        interruptEvent = nil
        actionWorkItem?.cancel()
        currentActionIndex = -1
    }
}


// MARK: - Convienence

private extension RoutineExecuter {
    var currentAction: RoutineItem.Payload.Action? {
        guard let item = routine, currentActionIndex < item.payload.actions.count else { return nil }

        return item.payload.actions[currentActionIndex]
    }
    
    var hasNextAction: Bool {
        guard let routine = routine else { return false }
        
        return (0..<routine.payload.actions.count - 1).contains(currentActionIndex)
    }
}


