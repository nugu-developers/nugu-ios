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

import NuguInterface

public class DialogStateAggregator: DialogStateAggregatable {
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
                    delegate.dialogStateDidChange(dialogState)
                }
            }
        }
    }
    private var asrState: ASRState = .idle
    private var ttsState: TTSState = .finished
    private var textAgentState: TextAgentState = .idle
    public var expectSpeech: ASRExpectSpeech? {
        didSet {
            applyState()
        }
    }

    public init() {
        log.info("")
    }

    deinit {
        log.info("")
    }
}

// MARK: - DialogStateAggregatable

extension DialogStateAggregator {
    public func add(delegate: DialogStateDelegate) {
        dialogStateDelegates.add(delegate)
    }

    public func remove(delegate: DialogStateDelegate) {
        dialogStateDelegates.remove(delegate)
    }
}

// MARK: - ASRAgentDelegate

extension DialogStateAggregator: ASRAgentDelegate {
    public func asrAgentDidChange(state: ASRState) {
        dialogStateDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.asrState = state
            self.applyState()
        }
    }
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

// MARK: - TextAgentDelegate

extension DialogStateAggregator: TextAgentDelegate {
    public func textAgentDidChange(state: TextAgentState) {
        dialogStateDispatchQueue.async { [weak self] in
            self?.textAgentState = state
            self?.applyState()
        }
    }
}

// MARK: - Private

private extension DialogStateAggregator {
    /// dialogStateDispatchQueue
    func applyState() {
        log.info("\(asrState)\(ttsState)")
        switch (asrState, textAgentState, ttsState) {
        case (_, _, .playing):
            dialogState = .speaking(expectingSpeech: expectSpeech != nil)
        case (.expectingSpeech, _, _):
            dialogState = .expectingSpeech
        case (.listening, _, _):
            dialogState = .listening
        case (.recognizing, _, _):
            dialogState = .recognizing
        case (.busy, _, _),
             (_, .busy, _):
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
            switch (self.asrState, self.textAgentState, self.ttsState) {
            case (.idle, .idle, let ttsState) where [.idle, .finished, .stopped].contains(ttsState):
                self.dialogState = .idle
            default:
                break
            }
        }
        multiturnSpeakingToListeningTimer = workItem
        dialogStateDispatchQueue.asyncAfter(deadline: .now() + shortTimeout, execute: workItem)
    }
}
