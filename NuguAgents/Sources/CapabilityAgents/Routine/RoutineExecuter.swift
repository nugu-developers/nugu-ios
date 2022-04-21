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

protocol RoutineExecuterDelegate: AnyObject {
    func routineExecuterDidChange(state: RoutineState)

    func routineExecuterShouldRequestAction(
        action: RoutineItem.Payload.Action,
        referrerDialogRequestId: String,
        completion: @escaping (StreamDataState) -> Void
    ) -> EventIdentifier
}

class RoutineExecuter {
    weak var delegate: RoutineExecuterDelegate?
    
    private(set) var routine: RoutineItem?
    var routineActionIndex: Int? {
        guard currentActionIndex >= 0 else { return nil }
        
        return currentActionIndex
    }
    private(set) var state: RoutineState = .idle {
        didSet {
            log.debug(state)
            
            guard oldValue != state else {
                log.debug("state has not changed. \(oldValue) -> \(state)")
                return
            }
            
            interruptTimer?.cancel()
            switch state {
            case .idle:
                break
            case .playing:
                break
            case .interrupted:
                // Interrupt 이후 60초 이내에 Routine.Continue directive 를 받지 못하면 Routine 종료.
                if hasNextAction {
                    actionWorkItem?.cancel()
                    if let dialogRequestId = handlingEvent {
                        directiveSequencer.cancelDirective(dialogRequestId: dialogRequestId)
                    }
                    let item = DispatchWorkItem { [weak self] in
                        guard let self = self, self.state == .interrupted else { return }
                        
                        self.doStop()
                    }
                    interruptTimer = item
                    routineDispatchQueue.asyncAfter(deadline: .now() + 60, execute: item)
                } else {
                    state = .stopped
                }
            case .finished, .stopped:
                if let dialogRequestId = handlingEvent {
                    directiveSequencer.cancelDirective(dialogRequestId: dialogRequestId)
                }
                actionWorkItem?.cancel()
            }
            
            delegate?.routineExecuterDidChange(state: state)
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
    private var ignoreAfterAction = false
    
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

            self.handlingDirectives.removeAll()
            self.handlingEvent = nil
            self.interruptEvent = nil
            self.currentActionIndex = 0
            self.ignoreAfterAction = false
            
            self.doFinish()
            
            self.routine = routine
            self.state = .playing

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
            // Routine Action 에 의한 directive 실행 결과에 따른 처리
            guard let self = self, self.state == .playing,
                  self.handlingDirectives.remove(notification.directive.header.messageId) != nil else { return }
            
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
                // 마지막 directive 가 실행완료 되면 다음 Action 실행
                if self.handlingDirectives.isEmpty {
                    self.doNextAction()
                }
            }
        }
        notificationTokens.append(token)
    }

    func addAsrAgentObserver(_ asrAgent: ASRAgentProtocol) {
        let token = asrAgent.observe(NuguAgentNotification.ASR.StartRecognition.self, queue: routineDispatchQueue) { [weak self] (notification) in
            guard let self = self, self.state == .playing else { return }
            
            // ASR.Recognize event 발생시 interrupt 처리
            if self.doInterrupt() == true {
                log.debug("")
                self.interruptEvent = notification.dialogRequestId
            }
        }
        notificationTokens.append(token)
    }

    func addStreamDataObserver(_ streamDataRouter: StreamDataRoutable) {
        let directivesToken = streamDataRouter.observe(NuguCoreNotification.StreamDataRoute.ReceivedDirectives.self, queue: routineDispatchQueue) { [weak self] (notification) in
            guard let self = self, self.state == .playing else { return }
            
            // Directive 에 Routine 중단 대상이 포함되어 있으며, 다음 Action 은 실행되지 않음
            if (notification.directives.contains { self.stopTargets.contains($0.header.type) }), self.hasNextAction {
                log.debug("")
                self.ignoreAfterAction = true
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
            guard let self = self, self.state == .playing else { return }
            
            // Event 가 Routine interrupt 대상에 포함되어 있으며, Action 에 의한 event 가 아닌 경우 interrupt 처리.
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
        guard state == .playing, let routine = routine, let action = currentAction else { return }
        
        let completion: ((StreamDataState) -> Void) = { [weak self] result in
            log.debug(result)
            if case .error = result {
                self?.doNextAction()
            }
        }
        
        log.debug(action.actionType)
        // Actin 규격에 문제가 있는 경우 다음 Action 으로 넘어감
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
        actionWorkItem?.cancel()
        
        if let delay = currentAction?.postDelay {
            log.debug(delay)
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                guard self.state == .playing, self.hasNextAction else {
                    self.doFinish()
                    return
                }

                self.currentActionIndex += 1
                self.doAction()
            }
            actionWorkItem = workItem
            routineDispatchQueue.asyncAfter(deadline: .now() + delay.dispatchTimeInterval, execute: workItem)
        } else {
            guard state == .playing, hasNextAction else {
                doFinish()
                return
            }
            
            log.debug("")
            
            self.currentActionIndex += 1
            self.doAction()
        }
    }

    @discardableResult
    func doInterrupt() -> Bool {
        guard state == .playing else { return false }
        
        log.debug("")
        state = .interrupted

        return true
    }
    
    func doStop() {
        guard [.playing, .interrupted].contains(state) else { return }
        
        log.debug("")
        state = .stopped
    }

    func doFinish() {
        guard state == .playing else { return }
        
        log.debug("")
        state = .finished
    }
}

// MARK: - Convienence

private extension RoutineExecuter {
    var currentAction: RoutineItem.Payload.Action? {
        guard let routine = routine, currentActionIndex < routine.payload.actions.count else { return nil }

        return routine.payload.actions[currentActionIndex]
    }
    
    var hasNextAction: Bool {
        guard let routine = routine, routine.payload.actions.count - 1 > 0 else { return false }
        
        return (0..<routine.payload.actions.count - 1).contains(currentActionIndex) && ignoreAfterAction == false
    }
}
