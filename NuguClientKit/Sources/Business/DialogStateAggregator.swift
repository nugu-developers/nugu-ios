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

/// DialogStateAggregator aggregate several components state into one.
public class DialogStateAggregator {
    private let dialogStateDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.dialog_state_aggregator", qos: .userInitiated)
    private let dialogStateDelegates = DelegateSet<DialogStateDelegate>()
    
    private let shortTimeout: DispatchTimeInterval = .milliseconds(200)
    private var multiturnSpeakingToListeningTimer: DispatchWorkItem?

    private var dialogState: DialogState = .idle {
        didSet {
            log.info("\(oldValue) \(dialogState)")

            if oldValue != dialogState {
                multiturnSpeakingToListeningTimer?.cancel()
                dialogStateDelegates.notify { delegate in
                    delegate.dialogStateDidChange(dialogState, expectSpeech: expectSpeech)
                }
            }
        }
    }
    private var asrState: ASRState = .idle
    private var expectSpeech: ASRExpectSpeech?
    private var ttsState: TTSState = .finished
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

extension DialogStateAggregator: ASRAgentDelegate {
    public func asrAgentDidChange(state: ASRState, expectSpeech: ASRExpectSpeech?) {
        dialogStateDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.asrState = state
            self.expectSpeech = expectSpeech
            self.applyState()
        }
    }
    
    public func asrAgentDidReceive(result: ASRResult, dialogRequestId: String) {}
}

// MARK: - TTSAgentDelegate

extension DialogStateAggregator: TTSAgentDelegate {
    public func ttsAgentDidReceive(text: String, dialogRequestId: String) {
    }
    
    public func ttsAgentDidChange(state: TTSState, dialogRequestId: String) {
        dialogStateDispatchQueue.async { [weak self] in
            self?.ttsState = state
            self?.applyState()
        }
    }
}

// MARK: - Private

private extension DialogStateAggregator {
    /// dialogStateDispatchQueue
    func applyState() {
        log.info("\(asrState)\(ttsState)")
        switch (asrState, ttsState) {
        case (_, .playing):
            dialogState = .speaking
        case (.expectingSpeech, _):
            dialogState = .expectingSpeech
        case (.listening, _):
            dialogState = .listening
        case (.recognizing, _):
            dialogState = .recognizing
        case (.busy, _):
            dialogState = .thinking
        default:
            tryEnterIdleState()
        }
    }
    
    func tryEnterIdleState() {
        log.info("")
        guard dialogState != .idle else { return }

        multiturnSpeakingToListeningTimer?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
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
