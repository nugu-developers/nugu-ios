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
public class DialogStateAggregator {
    private let dialogStateDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.dialog_state_aggregator", qos: .userInitiated)
    
    private let sessionManager: SessionManageable
    private let focusManager: FocusManageable
    
    private let shortTimeout: DispatchTimeInterval = .milliseconds(200)
    private var multiturnSpeakingToListeningTimer: DispatchWorkItem?
    
    private var currentChips: (dialogRequestId: String, item: ChipsAgentItem)?

    private var dialogState: DialogState = .idle {
        didSet {
            log.info("from \(oldValue) to \(dialogState) isMultiturn \(isMultiturn)")

            multiturnSpeakingToListeningTimer?.cancel()
            
            var chipsItem: ChipsAgentItem?
            if sessionManager.activeSessions.last?.dialogRequestId == currentChips?.dialogRequestId {
                chipsItem = currentChips?.item
            } else {
                // Delete the chips if it is not for the most recently active session.
                currentChips = nil
            }
            
            var userInfo: [AnyHashable: Any] = [ObservingFactor.State.state: dialogState,
                                                ObservingFactor.State.multiturn: isMultiturn,
                                                ObservingFactor.State.sessionActivated: sessionActivated]
            if let chips = chipsItem?.chips {
                userInfo[ObservingFactor.State.chips] = chips
            }
            
            notificationCenter.post(name: .dialogStateDidChange, object: self, userInfo: userInfo)
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

public extension Notification.Name {
    static let dialogStateDidChange = Notification.Name("com.sktelecom.romaine.notification.name.dialog_state_did_change")
}

extension DialogStateAggregator: Observing {
    public enum ObservingFactor {
        public enum State: ObservingSpec {
            case state
            case multiturn
            case chips
            case sessionActivated
            
            public var name: Notification.Name {
                .dialogStateDidChange
            }
        }
    }
}

/// :nodoc:
private extension DialogStateAggregator {
    func addChipsAgentObserver(_ object: ChipsAgentProtocol) {
        chipsAgentObserver = notificationCenter.addObserver(forName: .chipsAgentDidReceive, object: object, queue: nil) { [weak self] (notification) in
            guard let item = notification.userInfo?[ChipsAgent.ObservingFactor.Receive.item] as? ChipsAgentItem,
                  let header = notification.userInfo?[ChipsAgent.ObservingFactor.Receive.header] as? Downstream.Header else { return }
            
            self?.dialogStateDispatchQueue.async { [weak self] in
                if item.target == .dialog {
                    self?.currentChips = (dialogRequestId: header.dialogRequestId, item: item)
                }
            }
        }
    }
    
    func addInteractionControlObserver(_ object: InteractionControlManageable) {
        interactionControlObserver = notificationCenter.addObserver(forName: .interactionControlDidChange, object: object, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            guard let isMultiturn = notification.userInfo?[InteractionControlManager.ObservingFactor.MultiTurn.multiTurn] as? Bool else { return }
            
            log.debug(self.isMultiturn)
            self.dialogStateDispatchQueue.async { [weak self] in
                self?.isMultiturn = isMultiturn
                if isMultiturn == false {
                    self?.tryEnterIdleState()
                }
            }
        }
    }
    
    func addAsrAgentObserver(_ object: ASRAgentProtocol) {
        asrStateObserver = notificationCenter.addObserver(forName: .asrAgentStateDidChange, object: object, queue: .main) { [weak self] (notification) in
            self?.dialogStateDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard let state = notification.userInfo?[ASRAgent.ObservingFactor.State.state] as? ASRState else { return }
                
                self.asrState = state
                switch state {
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
        ttsStateObserver = notificationCenter.addObserver(forName: .ttsAgentStateDidChange, object: object, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            guard let state = notification.userInfo?[TTSAgent.ObservingFactor.State.state] as? TTSState else { return }
            
            self.dialogStateDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                self.ttsState = state
                switch state {
                case .idle:
                    break
                case .playing:
                    self.dialogState = .speaking
                case .finished, .stopped:
                    self.tryEnterIdleState()
                }
            }
        }
        
        ttsResultObserver = notificationCenter.addObserver(forName: .ttsAgentResultDidReceive, object: object, queue: nil) { (notification) in
            // Nothing to do
        }
    }
}
