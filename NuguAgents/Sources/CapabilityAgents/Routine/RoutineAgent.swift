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
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .routine, version: "1.2")

    // RoutineAgentProtocol
    public weak var delegate: RoutineAgentDelegate?
    
    public var state: RoutineState { routineExecuter.state }
    public var routineItem: RoutineItem? { routineExecuter.routine }
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    private let routineExecuter: RoutineExecuter

    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Start", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleStart),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Stop", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleStop),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Continue", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleContinue)
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
                "type": action.type,
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
            "routineActivity": self.routineExecuter.state.routineActivity,
            "currentAction": self.routineExecuter.routineActionIndex?.advanced(by: 1),
            "actions": actions
        ]

        completion(
            ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 })
        )
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
        }
        
        delegate?.routineAgentDidChange(state: state, item: routine)
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
