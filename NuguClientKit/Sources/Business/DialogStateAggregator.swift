//
//  DialogStateAggregator.swift
//  NuguClientKit
//
//  Created by MinChul Lee on 17/04/2019.
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
import NuguAgents
import NuguUtils

/// DialogStateAggregator aggregate several components state into one.
public class DialogStateAggregator: TypedNotifyable {
    private let dialogStateDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.dialog_state_aggregator", qos: .userInitiated)
    
    private let sessionManager: SessionManageable
    private let focusManager: FocusManageable
    
    private let shortTimeout: DispatchTimeInterval = .milliseconds(200)
    private var multiturnSpeakingToListeningTimer: DispatchWorkItem?
    
    private var currentChips: (dialogRequestId: String, item: ChipsAgentItem)?

    private var dialogState: DialogState = .idle {
        didSet {
            log.info("dialogState is changed from \(oldValue) to \(dialogState) isMultiturn \(isMultiturn)")

            multiturnSpeakingToListeningTimer?.cancel()
            
            // https://tde.sktelecom.com/pms/browse/NUGUSDKQA-225
            // Chips should be cleared when,
            // Listening state excluding ExpectSpeech initiator
            // And include any nudge type chip in item.chips array
            // multiturn should be canceled also in this situation
            if case .listening(let initiator) = asrState,
               initiator != .expectSpeech,
               let currentChips = currentChips,
               currentChips.item.chips.filter({ $0.type == .nudge }).count != 0 {
                isMultiturn = false
                self.currentChips = nil
            }
            
            var chipsItem: ChipsAgentItem?
            switch currentChips?.item.target {
            case .dialog where sessionManager.activeSessions.last?.dialogRequestId == currentChips?.dialogRequestId:
                chipsItem = currentChips?.item
            case .listen where isMultiturn:
                if dialogState == .listening {
                    chipsItem = currentChips?.item
                }
            case .speaking:
                if dialogState == .speaking {
                    chipsItem = currentChips?.item
                }
            default:
                // Delete the chips if it is not for the most recently active session.
                currentChips = nil
                log.debug("current chips are cleared")
            }
            
            let typedNotification = NuguClientNotification.DialogState.State(state: dialogState, multiTurn: isMultiturn, item: chipsItem, sessionActivated: sessionActivated)
            notificationCenter.post(name: .dialogStateDidChange, object: self, userInfo: typedNotification.dictionary)
        }
    }
    private var asrState: ASRState = .idle
    private var ttsState: TTSState = .finished
    
    /// <#Description#>
    public var sessionActivated: Bool {
        sessionManager.activeSessions.isEmpty == false
    }
    /// <#Description#>
    public var isMultiturn: Bool = false
    // TODO: Refactor
    /// <#Description#>
    public var isChipsRequestInProgress: Bool = false {
        didSet {
            log.debug(isChipsRequestInProgress)
            dialogStateDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                if self.isChipsRequestInProgress == false {
                    self.tryEnterIdleState()
                }
            }
        }
    }
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var asrStateObserver: Any?
    private var ttsStateObserver: Any?
    private var ttsResultObserver: Any?
    private var chipsAgentObserver: Any?
    private var interactionControlObserver: Any?
    
    init(
        sessionManager: SessionManageable,
        interactionControlManager: InteractionControlManageable,
        focusManager: FocusManageable,
        asrAgent: ASRAgentProtocol,
        ttsAgent: TTSAgentProtocol,
        chipsAgent: ChipsAgentProtocol
    ) {
        self.sessionManager = sessionManager
        self.focusManager = focusManager
        
        // Observers
        addAsrAgentObserver(asrAgent)
        addTtsAgentObserver(ttsAgent)
        addChipsAgentObserver(chipsAgent)
        addInteractionControlObserver(interactionControlManager)
    }
    
    deinit {
        if let asrStateObserver = asrStateObserver {
            notificationCenter.removeObserver(asrStateObserver)
        }
        
        if let chipsAgentObserver = chipsAgentObserver {
            notificationCenter.removeObserver(chipsAgentObserver)
        }
        
        if let interactionControlObserver = interactionControlObserver {
            notificationCenter.removeObserver(interactionControlObserver)
        }
        
        if let ttsStateObserver = ttsStateObserver {
            notificationCenter.removeObserver(ttsStateObserver)
        }
        
        if let ttsResultObserver = ttsResultObserver {
            notificationCenter.removeObserver(ttsResultObserver)
        }
    }
}

// MARK: - Private

/// :nodoc:
private extension DialogStateAggregator {
    /// dialogStateDispatchQueue
    func tryEnterIdleState() {
        log.info("")
        guard dialogState != .idle else { return }

        multiturnSpeakingToListeningTimer?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard self.isMultiturn == false, self.isChipsRequestInProgress == false else { return }
            switch (self.asrState, self.ttsState) {
            case (.idle, let ttsState) where [.idle, .finished, .stopped].contains(ttsState):
                self.dialogState = .idle
            default:
                break
            }
        }
        multiturnSpeakingToListeningTimer = workItem
        dialogStateDispatchQueue.asyncAfter(deadline: .now() + shortTimeout, execute: workItem)
    }
}

// MARK: - Observers

extension Notification.Name {
    static let dialogStateDidChange = Notification.Name("com.sktelecom.romaine.notification.name.dialog_state_did_change")
}

public extension NuguClientNotification {
    enum DialogState {
        public struct State: TypedNotification {
            public static let name: Notification.Name = .dialogStateDidChange
            public let state: NuguClientKit.DialogState
            public let multiTurn: Bool
            public let item: ChipsAgentItem?
            public let sessionActivated: Bool
            
            public static func make(from: [String: Any]) -> State? {
                guard let state = from["state"] as? NuguClientKit.DialogState,
                      let multiTurn = from["multiTurn"] as? Bool,
                      let sessionActivated = from["sessionActivated"] as? Bool else { return nil }
                
                let item = from["item"] as? ChipsAgentItem
                return State(state: state, multiTurn: multiTurn, item: item, sessionActivated: sessionActivated)
            }
        }
    }
}

/// :nodoc:
private extension DialogStateAggregator {
    func addChipsAgentObserver(_ object: ChipsAgentProtocol) {
        chipsAgentObserver = object.observe(NuguAgentNotification.Chips.Receive.self, queue: nil) { [weak self] (notification) in
            self?.dialogStateDispatchQueue.async { [weak self] in
                self?.currentChips = (dialogRequestId: notification.header.dialogRequestId, item: notification.item)
            }
        }
    }
    
    func addInteractionControlObserver(_ object: InteractionControlManageable) {
        interactionControlObserver = object.observe(NuguAgentNotification.InteractionControl.MultiTurn.self, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            
            log.debug(self.isMultiturn)
            self.dialogStateDispatchQueue.async { [weak self] in
                self?.isMultiturn = notification.multiTurn
                if notification.multiTurn == false {
                    self?.tryEnterIdleState()
                }
            }
        }
    }
    
    func addAsrAgentObserver(_ object: ASRAgentProtocol) {
        asrStateObserver = object.observe(NuguAgentNotification.ASR.State.self, queue: nil) { [weak self] (notification) in
            self?.dialogStateDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                self.asrState = notification.state
                switch notification.state {
                case .idle:
                    self.tryEnterIdleState()
                case .listening:
                    self.dialogState = .listening
                case .recognizing:
                    self.dialogState = .recognizing
                case .busy:
                    self.dialogState = .thinking
                case .expectingSpeech:
                    break
                }
            }
        }
    }
    
    func addTtsAgentObserver(_ object: TTSAgentProtocol) {
        ttsStateObserver = object.observe(NuguAgentNotification.TTS.State.self, queue: nil) { [weak self] (notification) in
            self?.dialogStateDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                self.ttsState = notification.state
                switch self.ttsState {
                case .idle:
                    break
                case .playing:
                    self.dialogState = .speaking
                case .finished, .stopped:
                    self.tryEnterIdleState()
                }
            }
        }
    }
}
