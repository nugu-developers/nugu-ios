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
    func routineExecuterShouldSendActionTriggerTimout(token: String)
    func routineExecuterWillProcessAction(_ action: RoutineItem.Payload.Action)
    func routineExecuterDidStopProcessingAction(_ action: RoutineItem.Payload.Action)
    func routineExecuterDidFinishProcessingAction(_ action: RoutineItem.Payload.Action)
    func routineExecuterCanExecuteNextAction(_ action: RoutineItem.Payload.Action) -> Bool
    
    func routineExecuterShouldRequestAction(
        action: RoutineItem.Payload.Action,
        referrerDialogRequestId: String,
        completion: @escaping (StreamDataState) -> Void
    ) -> EventIdentifier
}

class RoutineExecuter {
    typealias ReceivedDirectives = NuguCoreNotification.StreamDataRoute.ReceivedDirectives
    
    private enum Const {
        static let reactiveTarget = "Adot.Reactive"
    }
    
    weak var delegate: RoutineExecuterDelegate?
    
    private(set) var routine: RoutineItem?
    var routineActionIndex: Int? {
        guard currentActionIndex >= 0 else { return nil }
        
        return currentActionIndex
    }
    private(set) var state: RoutineState = .idle {
        didSet {
            guard oldValue != state else {
                log.debug("state has not changed. \(oldValue) -> \(state)")
                return
            }
            log.debug("routine state: \(state)")
            
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
                    // Interrupt 이후 interruptTimeoutInSeconds 이내에 Routine.Continue directive 를 받지 못하면 Routine 종료.
                    if let interruptTimeoutInSeconds = interruptTimeoutInSeconds {
                        let item = DispatchWorkItem { [weak self] in
                            guard let self = self, self.state == .interrupted else { return }
                            
                            self.doStop()
                        }
                        interruptTimer = item
                        routineDispatchQueue.asyncAfter(deadline: .now() + .seconds(interruptTimeoutInSeconds), execute: item)
                    }
                } else {
                    state = .stopped
                }
            case .finished, .stopped:
                if let dialogRequestId = handlingEvent {
                    directiveSequencer.cancelDirective(dialogRequestId: dialogRequestId)
                }
                actionWorkItem?.cancel()
            case .suspended:
                break
            }
            
            delegate?.routineExecuterDidChange(state: state)
        }
    }
    
    var interruptTimeoutInSeconds: Int? = 60
    
    private let directiveSequencer: DirectiveSequenceable
    private let textAgent: TextAgentProtocol
    
    private let stopTargets = ["ASR.ExpectSpeech"]
    private let interruptTargets = ["Text.TextInput", "ASR.Recognize"]
    private let delayTargets = ["TTS.Speak"]
    
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
    
    private var ignoreStopEvent = false
    private var ignoreInterruptEvents = Set<String>()
    private var shouldDelayAction = false
    
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
            self.ignoreInterruptEvents.removeAll()
            
            self.doFinish()
            
            self.routine = routine
            self.state = .playing
            
            self.doAction()
        }
    }
    
    func pause() {
        routineDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            log.debug("pause routine")
            self.doInterrupt()
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
    
    func move(to index: Int, completion: @escaping (Bool) -> Void) {
        routineDispatchQueue.async { [weak self] in
            guard let self = self, let action = self.currentAction else { return }
            guard [.playing, .interrupted, .suspended].contains(self.state),
                  let routine = self.routine, (0..<routine.payload.actions.count).contains(index) else {
                completion(false)
                return
            }
            
            if [.interrupted, .suspended].contains(self.state) {
                self.actionWorkItem?.cancel()
                self.state = .playing
            }
            
            self.delegate?.routineExecuterDidStopProcessingAction(action)
            self.cancelCurrentAction()
            
            log.debug("moved to index: \(index)")
            self.currentActionIndex = index
            self.ignoreStopEvent = true
            self.doAction()
            completion(true)
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
            
            log.debug("completed directive: \(notification), handlingDirectives: \(self.handlingDirectives)")
            switch notification.result {
            case .canceled:
                self.doStop()
            case .stopped(let policy):
                switch policy.cancelAll {
                case true:
                    if self.handlingDirectives.contains(notification.directive.header.messageId) {
                        self.doNextAction()
                    } else {
                        self.doInterrupt()
                    }
                    
                    self.handlingDirectives.removeAll()
                // Ignore stop event after action move event
                case false where self.ignoreStopEvent == true:
                    self.ignoreStopEvent = false
                case false where self.ignoreStopEvent == false:
                    self.doInterrupt()
                default:
                    break
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
        let directivesToken = streamDataRouter.observe(ReceivedDirectives.self, queue: routineDispatchQueue) { [weak self] (notification) in
            guard let self = self, self.state == .playing else { return }
            
            // Set mute delay after actions If Directives contains `Apollo.Reactive` and not `TTS.Speak`
            self.shouldDelayAction = self.applyMuteDelayIfNeeded(notification: notification)
            
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
            
            // Event 가 Routine interrupt 대상에 포함되어 있으며, Move, Action 에 의한 event 가 아닌 경우 interrupt 처리.
            if self.interruptTargets.contains(notification.event.header.type),
               self.handlingEvent != notification.event.header.dialogRequestId,
               self.shouldInterruptEvent(dialogRequestId: notification.event.header.dialogRequestId) {
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
        delegate?.routineExecuterWillProcessAction(action)
        
        let completion: ((StreamDataState) -> Void) = { [weak self] result in
            log.debug(result)
            if case .error = result {
                self?.doNextAction()
            }
        }
        
        if let actionTimeout = action.actionTimeoutInMilliseconds,
           .zero < actionTimeout {
            state = .suspended
            DispatchQueue.global().asyncAfter(deadline: .now() + NuguTimeInterval(milliseconds: actionTimeout).seconds) { [weak self] in
                self?.delegate?.routineExecuterShouldSendActionTriggerTimout(token: action.token)
            }
        }
        
        log.debug(action.type)
        switch action.type {
        case .text:
            // Action 규격에 문제가 있는 경우 다음 Action 으로 넘어감
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
        case .break:
            doBreak()
        }
    }
    
    func doNextAction() {
        guard let action = currentAction else { return }
        actionWorkItem?.cancel()
        if shouldDelayAction, let delay = currentAction?.muteDelay {
            log.debug("Delaying action using mute delay, delay: \(delay.dispatchTimeInterval)")
            doActionAfter(delay: delay)
        } else if let delay = currentAction?.postDelay {
            log.debug("Delaying action using posy delay, delay: \(delay.dispatchTimeInterval)")
            doActionAfter(delay: delay)
        } else {
            delegate?.routineExecuterDidFinishProcessingAction(action)
            guard [.playing, .suspended].contains(state) else { return }
            guard hasNextAction else {
                doFinish()
                return
            }
            
            log.debug("")
            
            doNextActionIfContinueAction()
        }
    }
    
    @discardableResult
    func doInterrupt() -> Bool {
        guard [.playing, .suspended].contains(state) else { return false }
        
        log.debug("")
        state = .interrupted
        
        return true
    }
    
    func doStop() {
        guard [.playing, .interrupted, .suspended].contains(state) else { return }
        
        log.debug("")
        state = .stopped
    }
    
    func doFinish() {
        guard [.playing, .suspended].contains(state) else { return }
        
        log.debug("")
        state = .finished
    }
    
    func doBreak() {
        guard state == .playing, let action = currentAction else { return }
        
        actionWorkItem?.cancel()
        state = .suspended
        
        if let delay = currentAction?.muteDelay {
            log.debug("currentAction muteDelay: \(delay)")
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.delegate?.routineExecuterDidFinishProcessingAction(action)
                guard self.state == .suspended, self.hasNextAction else {
                    self.doFinish()
                    return
                }
                
                self.state = .playing
                self.doNextActionIfContinueAction()
            }
            actionWorkItem = workItem
            routineDispatchQueue.asyncAfter(deadline: .now() + delay.dispatchTimeInterval, execute: workItem)
        } else {
            delegate?.routineExecuterDidFinishProcessingAction(action)
            
            guard state == .suspended, hasNextAction else {
                doFinish()
                return
            }
            
            log.debug("")
            
            state = .playing
            doNextActionIfContinueAction()
        }
        
    }
    
    func applyMuteDelayIfNeeded(notification: ReceivedDirectives) -> Bool {
        guard (notification.directives.contains { Const.reactiveTarget == $0.header.type }) else {
            return false
        }
        return notification.directives.contains { delayTargets.contains($0.header.type) } == false
    }
    
    func doActionAfter(delay: TimeIntervallic) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, let action = self.currentAction else { return }
            self.delegate?.routineExecuterDidFinishProcessingAction(action)
            
            guard [.playing, .suspended].contains(state), self.hasNextAction else {
                self.doFinish()
                return
            }
            
            self.doNextActionIfContinueAction()
        }
        actionWorkItem = workItem
        routineDispatchQueue.asyncAfter(deadline: .now() + delay.dispatchTimeInterval, execute: workItem)
    }
    
    func shouldInterruptEvent(dialogRequestId: String) -> Bool {
        guard ignoreInterruptEvents.contains(dialogRequestId) else {
            return true
        }
        ignoreInterruptEvents.remove(dialogRequestId)
        return false
    }
    
    func cancelCurrentAction() {
        if let dialogRequestId = handlingEvent {
            ignoreInterruptEvents.insert(dialogRequestId)
            directiveSequencer.cancelDirective(dialogRequestId: dialogRequestId)
        }
        handlingDirectives.removeAll()
    }
    
    func doNextActionIfContinueAction() {
        guard let nextAction else { return }
        
        if delegate?.routineExecuterCanExecuteNextAction(nextAction) == true {
            currentActionIndex += 1
            doAction()
        } else {
            doInterrupt()
        }
    }
}

// MARK: - Convienence

private extension RoutineExecuter {
    var currentAction: RoutineItem.Payload.Action? {
        guard let routine = routine, currentActionIndex < routine.payload.actions.count else { return nil }
        
        return routine.payload.actions[currentActionIndex]
    }
    
    var nextAction: RoutineItem.Payload.Action? {
        guard let routine = routine, hasNextAction else { return nil }
        
        return routine.payload.actions[currentActionIndex + 1]
    }
    
    var hasNextAction: Bool {
        guard let routine = routine, routine.payload.actions.count - 1 > 0 else { return false }
        
        return (0..<routine.payload.actions.count - 1).contains(currentActionIndex) && ignoreAfterAction == false
    }
}
