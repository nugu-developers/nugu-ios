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
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var eventWillSendObserver: Any?
    private var eventDidSendObserver: Any?
    private var dialogStateObserver: Any?
    private var directivePrefetchObseerver: Any?
    private var directiveCompleteObseerver: Any?
    
    init(
        focusManager: FocusManageable,
        directiveSequener: DirectiveSequenceable,
        streamDataRouter: StreamDataRoutable,
        dialogStateAggregator: DialogStateAggregator
    ) {
        self.focusManager = focusManager
        
        focusManager.add(channelDelegate: self)
        
        // Observers
        addStreamDataRouterObserver(streamDataRouter)
        addDialogStateObserver(dialogStateAggregator)
        addDirectiveSequencerObserver(directiveSequener)
    }
    
    deinit {
        if let eventWillSendObserver = eventWillSendObserver {
            notificationCenter.removeObserver(eventWillSendObserver)
        }

        if let eventDidSendObserver = eventDidSendObserver {
            notificationCenter.removeObserver(eventDidSendObserver)
        }
        
        if let dialogStateObserver = dialogStateObserver {
            notificationCenter.removeObserver(dialogStateObserver)
        }
        
        if let directivePrefetchObseerver = directivePrefetchObseerver {
            notificationCenter.removeObserver(directivePrefetchObseerver)
        }
        
        if let directiveCompleteObseerver = directiveCompleteObseerver {
            notificationCenter.removeObserver(directiveCompleteObseerver)
        }
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

// MARK: - Observers

private extension BackgroundFocusHolder {
    func addStreamDataRouterObserver(_ object: StreamDataRoutable) {
        eventWillSendObserver = notificationCenter.addObserver(forName: .streamDataEventWillSend, object: object, queue: nil) { [weak self] (notification) in
            self?.queue.async { [weak self] in
                guard let self = self else { return }
                guard let event = notification.userInfo?[StreamDataRouter.ObservingFactor.EventWillSend.event] as? Upstream.Event else { return }
                
                if self.focusTargets.contains(event.header.type) {
                    self.handlingEvents.insert(event.header.messageId)
                    self.requestFocus()
                }
            }
        }
        
        eventDidSendObserver = notificationCenter.addObserver(forName: .streamDataEventDidSend, object: object, queue: nil) { [weak self] (notification) in
            self?.queue.async { [weak self] in
                guard let self = self else { return }
                guard let event = notification.userInfo?[StreamDataRouter.ObservingFactor.EventWillSend.event] as? Upstream.Event else { return }
                
                if self.handlingEvents.remove(event.header.messageId) != nil {
                    self.tryReleaseFocus()
                }
            }
        }
    }
    
    func addDialogStateObserver(_ object: DialogStateAggregator) {
        dialogStateObserver = notificationCenter.addObserver(forName: .dialogStateDidChange, object: object, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            guard let state = notification.userInfo?[DialogStateAggregator.ObservingFactor.State.state] as? DialogState else { return }
            
            self.queue.async { [weak self] in
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
    
    func addDirectiveSequencerObserver(_ object: DirectiveSequenceable) {
        directivePrefetchObseerver = notificationCenter.addObserver(forName: .directiveSequencerWillPrefetch, object: object, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            guard let directive = notification.userInfo?[DirectiveSequencer.ObservingFactor.Prefetch.directive] as? Downstream.Directive,
                  let blockingPolicy = notification.userInfo?[DirectiveSequencer.ObservingFactor.Prefetch.blockingPolicy] as? BlockingPolicy else { return }
            
            self.queue.async { [weak self] in
                guard let self = self else { return }
                
                if blockingPolicy.medium == .audio {
                    self.handlingSoundDirectives.insert(directive.header.messageId)
                    self.requestFocus()
                }
            }
        }
        
        directiveCompleteObseerver = notificationCenter.addObserver(forName: .directiveSequencerWillPrefetch, object: object, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            guard let directive = notification.userInfo?[DirectiveSequencer.ObservingFactor.Prefetch.directive] as? Downstream.Directive else { return }

            self.queue.async { [weak self] in
                guard let self = self else { return }
                
                if self.handlingSoundDirectives.remove(directive.header.messageId) != nil {
                    self.tryReleaseFocus()
                }
            }
        }
    }
}
