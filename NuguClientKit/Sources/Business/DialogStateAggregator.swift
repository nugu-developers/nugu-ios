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

    @Observing private var internalDialogState: DialogState = .idle
    private var dialogState: DialogState {
        get {
            internalDialogState
        }

        set {
            log.info("from \(dialogState) to \(newValue) isMultiturn \(isMultiturn)")

            multiturnSpeakingToListeningTimer?.cancel()
            
            var chipsItem: ChipsAgentItem?
            if sessionManager.activeSessions.last?.dialogRequestId == currentChips?.dialogRequestId {
                chipsItem = currentChips?.item
            } else {
                // Delete the chips if it is not for the most recently active session.
                currentChips = nil
            }
            
            var additionalInfo: [String: Any] = ["multiturn": isMultiturn,
                                  "sessionActivated": sessionActivated]
            if let chips = chipsItem?.chips {
                additionalInfo["chips"] = chips
            }

            _internalDialogState.additionalInfo = additionalInfo
            internalDialogState = newValue
        }
    }

    public var dialogStateObserverCotainer: Observing<DialogState>.ObserverContainer {
        $internalDialogState
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
        
        interactionControlManager.interactionStateObserverContainer.addObserver { [weak self] (state, additionalInfo) in
            log.debug("interaction state: \(state)")

            self?.dialogStateDispatchQueue.async { [weak self] in
                self?.isMultiturn = (state == .multi)
                if state != .multi {
                    self?.tryEnterIdleState()
                }
            }
        }
        
        // Observers
        asrAgent.asrStateObserverContainer.addObserver { [weak self] (state, additionalInfo) in
            self?.dialogStateDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
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
        
        asrAgent.asrResultObserverContainer.addObserver { (state, additionalInfo) in
            // Nothing to do
        }
        
        ttsAgent.ttsStateObserverContainer.addObserver { [weak self] (state, additionalInfo) in
            self?.dialogStateDispatchQueue.async { [weak self] in
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
        
        ttsAgent.receivedTextObserverContainer.addObserver { (text, additionalInfo) in
            // Nothing to do
        }
        
        chipsAgent.chipsItemObserverContainer.addObserver { [weak self] (item, additionalInfo) in
            self?.dialogStateDispatchQueue.async { [weak self] in
                if let item = item, item.target == .dialog,
                   let header = additionalInfo?["header"] as? Downstream.Header {
                    self?.currentChips = (dialogRequestId: header.dialogRequestId, item: item)
                }
            }
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
