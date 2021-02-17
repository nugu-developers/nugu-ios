//
//  NuguClient.swift
//  NuguClientKit
//
//  Created by childc on 06/02/2020.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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
import AVFoundation

import NuguCore
import NuguAgents

/// <#Description#>
public class NuguClient {
    public weak var delegate: NuguClientDelegate?
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var streamDataDirectiveDidReceive: Any?
    private var streamDataAttachmentDidReceive: Any?
    private var streamDataEventWillSend: Any?
    private var streamDataEventDidSend: Any?
    private var streamDataAttachmentDidSent: Any?
    private var dialogStateObserver: Any?
    
    // Core
    public let contextManager: ContextManageable
    public let focusManager: FocusManageable
    public let streamDataRouter: StreamDataRoutable
    public let directiveSequencer: DirectiveSequenceable
    public let playSyncManager: PlaySyncManageable
    public let dialogAttributeStore: DialogAttributeStoreable
    public let sessionManager: SessionManageable
    public let systemAgent: SystemAgentProtocol
    public let interactionControlManager: InteractionControlManageable
    
    // Default Agents
    public let asrAgent: ASRAgentProtocol
    public let ttsAgent: TTSAgentProtocol
    public let textAgent: TextAgentProtocol
    public let audioPlayerAgent: AudioPlayerAgentProtocol
    public let sessionAgent: SessionAgentProtocol
    public let chipsAgent: ChipsAgentProtocol
    public let utilityAgent: UtilityAgentProtocol

    // Additional Agents
    public lazy var mediaPlayerAgent: MediaPlayerAgentProtocol = MediaPlayerAgent(
        directiveSequencer: directiveSequencer,
        contextManager: contextManager,
        upstreamDataSender: streamDataRouter
    )
    
    public lazy var extensionAgent: ExtensionAgentProtocol = ExtensionAgent(
        upstreamDataSender: streamDataRouter,
        contextManager: contextManager,
        directiveSequencer: directiveSequencer
    )
    
    public lazy var phoneCallAgent: PhoneCallAgentProtocol = PhoneCallAgent(
        directiveSequencer: directiveSequencer,
        contextManager: contextManager,
        upstreamDataSender: streamDataRouter,
        interactionControlManager: interactionControlManager
    )
    
    public lazy var soundAgent: SoundAgentProtocol = SoundAgent(
        focusManager: focusManager,
        upstreamDataSender: streamDataRouter,
        contextManager: contextManager,
        directiveSequencer: directiveSequencer
    )
    
    public lazy var displayAgent: DisplayAgentProtocol = DisplayAgent(
        upstreamDataSender: streamDataRouter,
        playSyncManager: playSyncManager,
        contextManager: contextManager,
        directiveSequencer: directiveSequencer,
        sessionManager: sessionManager,
        interactionControlManager: interactionControlManager
    )
    
    public lazy var locationAgent: LocationAgentProtocol = LocationAgent(contextManager: contextManager)
    
    // Supports
    public let dialogStateAggregator: DialogStateAggregator
    public let speechRecognizerAggregator: SpeechRecognizerAggregatable
    public let audioSessionManager: AudioSessionManageable?
    public let keywordDetector: KeywordDetector
    
    // Private
    private var pausedByInterruption = false
    private let backgroundFocusHolder: BackgroundFocusHolder
    
    init(
        contextManager: ContextManageable,
        focusManager: FocusManageable,
        streamDataRouter: StreamDataRoutable,
        directiveSequencer: DirectiveSequenceable,
        playSyncManager: PlaySyncManageable,
        dialogAttributeStore: DialogAttributeStoreable,
        sessionManager: SessionManageable,
        systemAgent: SystemAgentProtocol,
        interactionControlManager: InteractionControlManageable,
        asrAgent: ASRAgentProtocol,
        ttsAgent: TTSAgentProtocol,
        textAgent: TextAgentProtocol,
        audioPlayerAgent: AudioPlayerAgentProtocol,
        sessionAgent: SessionAgentProtocol,
        chipsAgent: ChipsAgentProtocol,
        utilityAgent: UtilityAgentProtocol,
        audioSessionManager: AudioSessionManageable?,
        keywordDetector: KeywordDetector,
        speechRecognizerAggregator: SpeechRecognizerAggregatable,
        mediaPlayerAgent: MediaPlayerAgentProtocol?,
        extensionAgent: ExtensionAgentProtocol?,
        phoneCallAgent: PhoneCallAgentProtocol?,
        soundAgent: SoundAgentProtocol?,
        displayAgent: DisplayAgentProtocol?,
        locationAgent: LocationAgentProtocol?
    ) {
        // Core
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        self.focusManager = focusManager
        self.streamDataRouter = streamDataRouter
        self.playSyncManager = playSyncManager
        self.dialogAttributeStore = dialogAttributeStore
        self.sessionManager = sessionManager
        self.interactionControlManager = interactionControlManager
        self.systemAgent = systemAgent
        
        dialogStateAggregator = DialogStateAggregator(
            sessionManager: sessionManager,
            interactionControlManager: interactionControlManager,
            focusManager: focusManager,
            asrAgent: asrAgent,
            ttsAgent: ttsAgent,
            chipsAgent: chipsAgent
        )
        
        backgroundFocusHolder = BackgroundFocusHolder(
            focusManager: focusManager,
            directiveSequener: directiveSequencer,
            streamDataRouter: streamDataRouter,
            dialogStateAggregator: dialogStateAggregator
        )

        // Default Agents
        self.asrAgent = asrAgent
        self.ttsAgent = ttsAgent
        self.textAgent = textAgent
        self.audioPlayerAgent = audioPlayerAgent
        self.sessionAgent = sessionAgent
        self.chipsAgent = chipsAgent
        self.utilityAgent = utilityAgent
        
        // Supports
        self.audioSessionManager = audioSessionManager
        self.keywordDetector = keywordDetector
        self.speechRecognizerAggregator = speechRecognizerAggregator
        
        // Additional Agents
        // These agents won't be initiated before accessing
        if let mediaPlayerAgent = mediaPlayerAgent {
            self.mediaPlayerAgent = mediaPlayerAgent
        }
        
        if let soundAgent = soundAgent {
            self.soundAgent = soundAgent
        }
        
        if let extensionAgent = extensionAgent {
            self.extensionAgent = extensionAgent
        }

        if let phoneCallAgent = phoneCallAgent {
            self.phoneCallAgent = phoneCallAgent
        }
        
        if let displayAgent = displayAgent {
            self.displayAgent = displayAgent
        }
        
        if let locationAgent = locationAgent {
            self.locationAgent = locationAgent
        }
        
        // Wiring
        setupAudioSessionManager()
        setupSpeechRecognizerAggregator()
        setupAuthorizationStore()
        setupAudioSessionRequester()
        setupDialogStateAggregator(dialogStateAggregator)
        setupStreamDataRouter(streamDataRouter)
    }
    
    deinit {
        removeStreamDataRouterObservers()
        removeDialogStateObserver()
    }
}

// MARK: - Helper functions

public extension NuguClient {
    /// <#Description#>
    /// - Parameter completion: <#completion description#>
    func startReceiveServerInitiatedDirective(completion: ((StreamDataState) -> Void)? = nil) {
        streamDataRouter.startReceiveServerInitiatedDirective(completion: completion)
    }
    
    /// <#Description#>
    func stopReceiveServerInitiatedDirective() {
        streamDataRouter.stopReceiveServerInitiatedDirective()
    }
    
    /// Send event that needs a text-based recognition
    ///
    /// This function cancel speech recognition.(e.g. `ASRAgentProtocol.startRecognition(:initiator)`)
    /// Use `NuguClient.textAgent.requestTextInput` directly to request independent of speech recognition.
    ///
    /// - Parameters:
    ///   - text: The `text` to be recognized
    ///   - token: <#token description#>
    ///   - requestType: <#requestType description#>
    ///   - completion: The completion handler to call when the request is complete
    /// - Returns: The dialogRequestId for request.
    @discardableResult func requestTextInput(text: String, token: String? = nil, requestType: TextAgentRequestType, completion: ((StreamDataState) -> Void)? = nil) -> String {
        dialogStateAggregator.isChipsRequestInProgress = true

        return textAgent.requestTextInput(
            text: text,
            token: token,
            requestType: requestType
        ) { [weak self] state in
            switch state {
            case .sent:
                self?.asrAgent.stopRecognition()
            case .finished, .error:
                self?.dialogStateAggregator.isChipsRequestInProgress = false
            default: break
            }
            completion?(state)
        }
    }
}

// MARK: - AuthorizationStoreDelegate

/// :nodoc:
extension NuguClient: AuthorizationStoreDelegate {
    private func setupAuthorizationStore() {
        AuthorizationStore.shared.delegate = self
    }
    
    public func authorizationStoreRequestAccessToken() -> String? {
        delegate?.nuguClientRequestAccessToken()
    }
}

// MARK: - FocusManagerDelegate

/// :nodoc:
extension NuguClient: FocusDelegate {
    private func setupAudioSessionRequester() {
        focusManager.delegate = self
    }
    
    public func focusShouldAcquire() -> Bool {
        guard let audioSessionManager = audioSessionManager else {
            return delegate?.nuguClientWillRequireAudioSession() == true
        }

        return audioSessionManager.updateAudioSession(requestingFocus: true) == true
    }
    
    public func focusShouldRelease() {
        guard let audioSessionManager = audioSessionManager else {
            delegate?.nuguClientDidReleaseAudioSession()
            return
        }
        
        audioSessionManager.notifyAudioSessionDeactivation()

    }
}

// MARK: - Observers

/// :nodoc:
extension NuguClient {
    private func setupStreamDataRouter(_ object: StreamDataRoutable) {
        streamDataDirectiveDidReceive = object.observe(NuguCoreNotification.StreamDataRoute.ReceivedDirective.self, queue: nil) { [weak self] (notification) in
            self?.delegate?.nuguClientDidReceive(direcive: notification.directive)
        }
        
        streamDataAttachmentDidReceive = object.observe(NuguCoreNotification.StreamDataRoute.ReceivedAttachment.self, queue: nil) { [weak self] (notification) in
            self?.delegate?.nuguClientDidReceive(attachment: notification.attachment)
        }
        
        streamDataEventWillSend = object.observe(NuguCoreNotification.StreamDataRoute.ToBeSentEvent.self, queue: nil) { [weak self] (notification) in
            self?.delegate?.nuguClientWillSend(event: notification.event)
        }
        
        streamDataEventDidSend = object.observe(NuguCoreNotification.StreamDataRoute.SentEvent.self, queue: nil) { [weak self] (notification) in
            self?.delegate?.nuguClientDidSend(event: notification.event, error: notification.error)
        }
        
        streamDataAttachmentDidSent = object.observe(NuguCoreNotification.StreamDataRoute.SentAttachment.self, queue: nil) { [weak self] (notification) in
            self?.delegate?.nuguClientDidSend(attachment: notification.attachment, error: notification.error)
        }
    }
    
    private func removeStreamDataRouterObservers() {
        if let streamDataDirectiveDidReceive = streamDataDirectiveDidReceive {
            notificationCenter.removeObserver(streamDataDirectiveDidReceive)
        }
        
        if let streamDataAttachmentDidReceive = streamDataAttachmentDidReceive {
            notificationCenter.removeObserver(streamDataAttachmentDidReceive)
        }
        
        if let streamDataEventWillSend = streamDataEventWillSend {
            notificationCenter.removeObserver(streamDataEventWillSend)
        }
        
        if let streamDataEventDidSend = streamDataEventDidSend {
            notificationCenter.removeObserver(streamDataEventDidSend)
        }
        
        if let streamDataAttachmentDidSent = streamDataAttachmentDidSent {
            notificationCenter.removeObserver(streamDataAttachmentDidSent)
        }
    }
    
    func setupDialogStateAggregator(_ object: DialogStateAggregator) {
        addDialogStateObserver(object)
    }
    
    func addDialogStateObserver(_ object: DialogStateAggregator) {
        dialogStateObserver = object.observe(NuguClientNotification.DialogState.State.self, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            
            switch notification.state {
            case .idle:
                self.playSyncManager.resumeTimer(property: PlaySyncProperty(layerType: .info, contextType: .display))
            case .listening:
                self.playSyncManager.pauseTimer(property: PlaySyncProperty(layerType: .info, contextType: .display))
            default:
                break
            }
        }
    }
    
    func removeDialogStateObserver() {
        if let dialogStateObserver = dialogStateObserver {
            notificationCenter.removeObserver(dialogStateObserver)
        }
    }
}

// MARK: - AudioSessionManagerDelegate

extension NuguClient: AudioSessionManagerDelegate {
    private func setupAudioSessionManager() {
        audioSessionManager?.delegate = self
    }
    
    public func audioSessionInterrupted(type: AudioSessionManager.AudioSessionInterruptionType) {
        switch type {
        case .began:
            log.debug("Interruption began")
            // Interruption began, take appropriate actions

            if audioPlayerAgent.isPlaying == true {
                audioPlayerAgent.pause()
                // PausedByInterruption flag should not be changed before paused delegate method has been called
                // Giving small delay for changing flag value can be a solution for this situation
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.pausedByInterruption = true
                }
            }
            ttsAgent.stopTTS(cancelAssociation: false)
            speechRecognizerAggregator.stopListening()
        case .ended(let options):
            log.debug("Interruption ended")
            if options.contains(.shouldResume) {
                speechRecognizerAggregator.startListeningWithTrigger()
                if pausedByInterruption == true || audioPlayerAgent.isPlaying == true {
                    audioPlayerAgent.play()
                }
            }
        }
    }
    
    public func audioSessionRouteChanged(reason: AudioSessionManager.AudioSessionRouteChangeReason) {
        switch reason {
        case .oldDeviceUnavailable(let previousRoute):
            log.debug("Route changed due to oldDeviceUnavailable")
            if audioPlayerAgent.isPlaying == true {
                audioPlayerAgent.pause()
            }
            
            if previousRoute?.outputs.first?.portType == .carAudio {
                speechRecognizerAggregator.startListeningWithTrigger()
            }
        case .newDeviceAvailable:
            if audioSessionManager?.isCarplayConnected() == true {
                speechRecognizerAggregator.stopListening()
            }
        }
    }
    
    public func audioSessionWillDeactivate() {
        speechRecognizerAggregator.stopListening()
    }
    
    public func audioSessionDidDeactivate() {
        speechRecognizerAggregator.startListeningWithTrigger()
    }
}

// MARK: - SpeechRecognizerAggregatorDelegate
extension NuguClient: SpeechRecognizerAggregatorDelegate {
    private func setupSpeechRecognizerAggregator() {
        speechRecognizerAggregator.delegate = self
    }
    
    public func speechRecognizerWillUseMic(requestingFocus: Bool) {
        guard let audioSessionManager = audioSessionManager else {
            delegate?.nuguClientWillUseMic()
            return
        }

        // Control center does not work properly when mixWithOthers option has been included.
        // To avoid adding mixWithOthers option when audio player is in paused state,
        // update audioSession should be done only when requesting focus
        if requestingFocus {
            audioSessionManager.updateAudioSession(requestingFocus: true)
        }
    }
}
