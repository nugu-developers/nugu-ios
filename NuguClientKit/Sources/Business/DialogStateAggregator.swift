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
    private let dialogStateDelegates = DelegateSet<DialogStateDelegate>()
    
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
            dialogStateDelegates.notify { delegate in
                delegate.dialogStateDidChange(dialogState, isMultiturn: isMultiturn, chips: chipsItem?.chips, sessionActivated: sessionActivated)
            }
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
    var isChipsRequestInProgress: Bool = false {
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
        focusManager: FocusManageable
    ) {
        self.sessionManager = sessionManager
        self.focusManager = focusManager
        
        interactionControlManager.add(delegate: self)
    }
}

// MARK: - DialogStateAggregatable

extension DialogStateAggregator {
    /// Adds a delegate to be notified of DialogStateAggregator state changes.
    /// - Parameter delegate: The object to add.
    public func add(delegate: DialogStateDelegate) {
        dialogStateDelegates.add(delegate)
    }
    
    /// Removes a delegate from DialogStateAggregator.
    /// - Parameter delegate: The object to remove.
    public func remove(delegate: DialogStateDelegate) {
        dialogStateDelegates.remove(delegate)
    }
}

// MARK: - ASRAgentDelegate

/// :nodoc:
extension DialogStateAggregator: ASRAgentDelegate {
    public func asrAgentDidChange(state: ASRState) {
        dialogStateDispatchQueue.async { [weak self] in
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
    
    public func asrAgentDidReceive(result: ASRResult, dialogRequestId: String) {}
}

// MARK: - TTSAgentDelegate

/// :nodoc:
extension DialogStateAggregator: TTSAgentDelegate {
    public func ttsAgentDidReceive(text: String, header: Downstream.Header) {
    }
    
    public func ttsAgentDidChange(state: TTSState, header: Downstream.Header) {
        dialogStateDispatchQueue.async { [weak self] in
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
}

// MARK: - InteractionControlDelegate

/// :nodoc:
extension DialogStateAggregator: InteractionControlDelegate {
    public func interactionControlDidChange(isMultiturn: Bool) {
        log.debug(isMultiturn)
        dialogStateDispatchQueue.async { [weak self] in
            self?.isMultiturn = isMultiturn
            if isMultiturn == false {
                self?.tryEnterIdleState()
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

// MARK: - ChipsAgentDelegate

/// :nodoc:
extension DialogStateAggregator: ChipsAgentDelegate {
    public func chipsAgentDidReceive(item: ChipsAgentItem, header: Downstream.Header) {
        dialogStateDispatchQueue.async { [weak self] in
            if item.target == .dialog {
                self?.currentChips = (dialogRequestId: header.dialogRequestId, item: item)
            }
        }
    }
}
