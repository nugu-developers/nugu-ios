//
//  BackgroundFocusHolder.swift
//  NuguClientKit
//
//  Created by MinChul Lee on 2020/09/27.
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

class BackgroundFocusHolder {
    private let focusManager: FocusManageable
    private let directiveSequencer: DirectiveSequenceable
    private let streamDataRouter: StreamDataRoutable
    private let dialogStateAggregator: DialogStateAggregator
    
    private let queue = DispatchQueue(label: "com.sktelecom.romaine.dummy_focus_requester")
    // Prevent releasing focus while these event are being processed.
    private let focusTargets = [
        "Text.TextInput",
        "TTS.SpeechFinished",
        "AudioPlayer.PlaybackFinished",
        "MediaPlayer.PlaySuspended"
    ]
    
    private var handlingEvents = Set<String>()
    private var handlingSoundDirectives = Set<String>()
    private var dialogState: DialogState = .idle
    
    init(
        focusManager: FocusManageable,
        directiveSequencer: DirectiveSequenceable,
        streamDataRouter: StreamDataRoutable,
        dialogStateAggregator: DialogStateAggregator
    ) {
        self.focusManager = focusManager
        self.directiveSequencer = directiveSequencer
        self.streamDataRouter = streamDataRouter
        self.dialogStateAggregator = dialogStateAggregator
        
        focusManager.add(channelDelegate: self)
        directiveSequencer.addListener(self)
        streamDataRouter.addListener(self)
        
        dialogStateAggregator.dialogStateObserverCotainer.addObserver { [weak self] (state, additionalInfo) in
            self?.queue.async { [weak self] in
                guard let self = self else { return }
                
                self.dialogState = state
                if state == .idle {
                    self.tryReleaseFocus()
                } else {
                    self.requestFocus()
                }
            }
        }
    }
    
    deinit {
        directiveSequencer.removeListener(self)
        streamDataRouter.removeListener(self)
    }
}

// MARK: - FocusChannelDelegate

extension BackgroundFocusHolder: FocusChannelDelegate {
    func focusChannelPriority() -> FocusChannelPriority {
        .background
    }
    
    func focusChannelDidChange(focusState: FocusState) {
        log.debug(focusState)
    }
}

// MARK: - DirectiveSequencerDelegate

extension BackgroundFocusHolder: DirectiveSequencerListener {
    func directiveSequencerWillPrefetch(directive: Downstream.Directive, blockingPolicy: BlockingPolicy) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if blockingPolicy.medium == .audio {
                self.handlingSoundDirectives.insert(directive.header.messageId)
                self.requestFocus()
            }
        }
    }
    
    func directiveSequencerWillHandle(directive: Downstream.Directive, blockingPolicy: BlockingPolicy) {}
    
    func directiveSequencerDidComplete(directive: Downstream.Directive, result: DirectiveHandleResult) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if self.handlingSoundDirectives.remove(directive.header.messageId) != nil {
                self.tryReleaseFocus()
            }
        }
    }
}

// MARK: - StreamDataDelegate

extension BackgroundFocusHolder: StreamDataListener {
    func streamDataDidReceive(direcive: Downstream.Directive) {}
    
    func streamDataDidReceive(attachment: Downstream.Attachment) {}
    
    func streamDataWillSend(event: Upstream.Event) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if self.focusTargets.contains(event.header.type) {
                self.handlingEvents.insert(event.header.messageId)
                self.requestFocus()
            }
        }
    }
    
    func streamDataDidSend(event: Upstream.Event, error: Error?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if self.handlingEvents.remove(event.header.messageId) != nil {
                self.tryReleaseFocus()
            }
        }
    }
    
    func streamDataDidSend(attachment: Upstream.Attachment, error: Error?) {}
}

// MARK: - Private

private extension BackgroundFocusHolder {
    func requestFocus() {
        focusManager.requestFocus(channelDelegate: self)
    }
    
    func tryReleaseFocus() {
        guard handlingEvents.isEmpty,
              handlingSoundDirectives.isEmpty,
              dialogState == .idle else { return }
        
        focusManager.releaseFocus(channelDelegate: self)
    }
}
