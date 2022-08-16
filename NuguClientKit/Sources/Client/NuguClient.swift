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
    private var serverInitiatedDirectiveReceiverStateObserver: Any?
    
    // Core
    /**
     Gether the contexts from providers
     
     - seeAlso: `getContext` method
     */
    public let contextManager: ContextManageable
    
    /**
     Manage audio focus.
     
     You can adjust the audio when you've got multiple audio sources at once.
     */
    public let focusManager: FocusManageable
    
    /**
     Send an event to the server and Receive a directive from the server.
     */
    public let streamDataRouter: StreamDataRoutable
    
    /**
     Dispatch the directives to the registered agent.
     */
    public let directiveSequencer: DirectiveSequenceable
    
    /**
     TODO: 입력부탁
     */
    public let playSyncManager: PlaySyncManageable
    
    /**
     TODO: 입력부탁
     */
    public let dialogAttributeStore: DialogAttributeStoreable
    
    /**
     TODO: 입력부탁
     */
    public let sessionManager: SessionManageable
    
    /**
     Process the directives which is related to system.
     
     ex) Change the server to resolve bottle neck.
     */
    public let systemAgent: SystemAgentProtocol
    
    /**
     Indicates the scene(Play) state.
     TODO: 확인부탁
     */
    public let interactionControlManager: InteractionControlManageable
    
    // Default Agents
    /**
     Automatic Speech Recognition
     
     Request to process ASR using the voice data you pass.
     
     ~~~
     asrAgent.startRecognition(initiator: .user) { _ in
     // your codes
     }
     ~~~
     */
    public let asrAgent: ASRAgentProtocol
    
    /**
     Text To Speech
     
     Request Voice data which is synthesized from the text.
     
     ~~~
     ttsAgent.reqeustTts("Hello World")
     ~~~
     */
    public let ttsAgent: TTSAgentProtocol
    
    /**
     Request the intents as a text
     
     ~~~
     textAgent,requestTextInput(text: "Play some music", requestType: .normal)
     ~~~
     */
    public let textAgent: TextAgentProtocol
    
    /**
     Built-In Player that wraps AVPlayer
     */
    public let audioPlayerAgent: AudioPlayerAgentProtocol
    
    // TODO: 입력부탁
    public let sessionAgent: SessionAgentProtocol
    
    /**
     Recommend the other intents that are considered useful.
     */
    public let chipsAgent: ChipsAgentProtocol
    
    // TODO: 입력부탁
    public let utilityAgent: UtilityAgentProtocol
    
    // TODO: 입력부탁
    public let routineAgent: RoutineAgentProtocol
    /**
     Recommend a nugu operation intent
     */
    public let nudgeAgent: NudgeAgentProtocol
    
    // Additional Agents
    /**
     Play your own audio contents
     
     - seeAlso: `AudioPlayerAgent`
     */
    public lazy var mediaPlayerAgent: MediaPlayerAgentProtocol = MediaPlayerAgent(
        directiveSequencer: directiveSequencer,
        contextManager: contextManager,
        upstreamDataSender: streamDataRouter
    )
    
    /**
     Receive custom directives you made.
     */
    public lazy var extensionAgent: ExtensionAgentProtocol = ExtensionAgent(
        upstreamDataSender: streamDataRouter,
        contextManager: contextManager,
        directiveSequencer: directiveSequencer
    )
    
    /**
     Make a phone call
     */
    public lazy var phoneCallAgent: PhoneCallAgentProtocol = PhoneCallAgent(
        directiveSequencer: directiveSequencer,
        contextManager: contextManager,
        upstreamDataSender: streamDataRouter,
        interactionControlManager: interactionControlManager
    )
    
    /**
     Send a message (SMS)
     */
    
    public lazy var messageAgent: MessageAgentProtocol = MessageAgent(
        directiveSequencer: directiveSequencer,
        contextManager: contextManager,
        upstreamDataSender: streamDataRouter,
        interactionControlManager: interactionControlManager
    )
    
    /**
     Play some special sound on the special occasion
     */
    public lazy var soundAgent: SoundAgentProtocol = SoundAgent(
        focusManager: focusManager,
        upstreamDataSender: streamDataRouter,
        contextManager: contextManager,
        directiveSequencer: directiveSequencer
    )
    
    /**
     Show Graphical User Interface
     */
    public lazy var displayAgent: DisplayAgentProtocol = DisplayAgent(
        upstreamDataSender: streamDataRouter,
        playSyncManager: playSyncManager,
        contextManager: contextManager,
        directiveSequencer: directiveSequencer,
        sessionManager: sessionManager,
        interactionControlManager: interactionControlManager
    )
    
    /// Handles directives for system permission.
    public lazy var permissionAgent: PermissionAgentProtocol = PermissionAgent(
        contextManager: contextManager,
        directiveSequencer: directiveSequencer
    )
    
    /**
     Send a location information
     */
    public lazy var locationAgent: LocationAgentProtocol = LocationAgent(contextManager: contextManager)
    
    /**
     Set alerts
     */
    public lazy var alertsAgent: AlertsAgentProtocol = AlertsAgent(
        directiveSequencer: directiveSequencer,
        contextManager: contextManager,
        upstreamDataSender: streamDataRouter
    )
    
    // Supports
    /**
     Indicates the dialog state.
     */
    public let dialogStateAggregator: DialogStateAggregator
    
    /**
     ASR helper that manages `KeywordDetector`, `ASRAgent` and `Mic`
     
     You don't have to care about the ASR, KeywordDetector and Mic status. If you use this helper.
     
     And use this helper rather than `AsrAgent`
     
     ~~~
     speechRecognizerAggregator.startListening(initiator: .user)
     ~~~
     */
    public let speechRecognizerAggregator: SpeechRecognizerAggregatable
    
    /**
     Manage `AVAudioSession`
     
     ~~~
     let isUpdated = audioSessionManager.updateAudioSessionToPlaybackIfNeeded(mixWithOthers: true)
     ~~~
     */
    public let audioSessionManager: AudioSessionManageable?
    
    /**
     Keyword Detector.
     
     Detects an "aria" statement.
     
     ~~~
     keywordDetector.start()
     ~~~
     */
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
        routineAgent: RoutineAgentProtocol,
        audioSessionManager: AudioSessionManageable?,
        keywordDetector: KeywordDetector,
        speechRecognizerAggregator: SpeechRecognizerAggregatable,
        mediaPlayerAgent: MediaPlayerAgentProtocol?,
        extensionAgent: ExtensionAgentProtocol?,
        phoneCallAgent: PhoneCallAgentProtocol?,
        messageAgent: MessageAgentProtocol?,
        soundAgent: SoundAgentProtocol?,
        displayAgent: DisplayAgentProtocol?,
        locationAgent: LocationAgentProtocol?,
        permissionAgent: PermissionAgentProtocol?,
        alertsAgent: AlertsAgentProtocol?,
        nudgeAgent: NudgeAgentProtocol
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
        self.routineAgent = routineAgent
        self.nudgeAgent = nudgeAgent
        
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
        
        if let messageAgent = messageAgent {
            self.messageAgent = messageAgent
        }
        
        if let displayAgent = displayAgent {
            self.displayAgent = displayAgent
        }
        
        if let locationAgent = locationAgent {
            self.locationAgent = locationAgent
        }
        
        if let permissionAgent = permissionAgent {
            self.permissionAgent = permissionAgent
        }
        
        if let alertsAgent = alertsAgent {
            self.alertsAgent = alertsAgent
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

// Wraps frequently used functions of agents
public extension NuguClient {
    /**
     Connect to the server and keep it.
     
     The server can send some directives at certain times.
     */
    func startReceiveServerInitiatedDirective(completion: ((StreamDataState) -> Void)? = nil) {
        ConfigurationStore.shared.registryServerUrl { [weak self] result in
            switch result {
            case .failure(let error):
                completion?(.error(error))
            case .success(let url):
                NuguServerInfo.registryServerAddress = url
                self?.streamDataRouter.startReceiveServerInitiatedDirective(completion: completion)
            }
        }
    }
    
    /**
     Stop receiving server-initiated-directive.
     */
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
    ///   - token: token
    ///   - requestType: `TextAgentRequestType`
    ///   - completion: The completion handler to call when the request is complete
    /// - Returns: The dialogRequestId for request.
    @discardableResult func requestTextInput(
        text: String,
        token: String? = nil,
        source: TextInputSource? = nil,
        requestType: TextAgentRequestType,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        dialogStateAggregator.isChipsRequestInProgress = true
        
        return textAgent.requestTextInput(
            text: text,
            token: token,
            source: source,
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
            return delegate?.nuguClientShouldUpdateAudioSessionForFocusAquire() == true
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
        // Observers
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
        
        serverInitiatedDirectiveReceiverStateObserver = object.observe(NuguCoreNotification.StreamDataRoute.ServerInitiatedDirectiveReceiverState.self, queue: nil) { [weak self] (notification) in
            self?.delegate?.nuguClientServerInitiatedDirectiveRecevierStateDidChange(notification)
        }
        
        // Device gateway address
        ConfigurationStore.shared.l4SwitchUrl { result in
            guard case let .success(url) = result else {
                return
            }
            
            NuguServerInfo.l4SwitchAddress = url
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
        
        if let serverInitiatedDirectiveReceiverStateObserver = serverInitiatedDirectiveReceiverStateObserver {
            notificationCenter.removeObserver(serverInitiatedDirectiveReceiverStateObserver)
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
    
    public func speechRecognizerStateDidChange(_ state: SpeechRecognizerAggregatorState) {
        delegate?.nuguClientDidChangeSpeechState(state)
        notificationCenter.post(name: NuguClient.speechStateChangedNotification, object: self, userInfo: ["state": state])
    }
}

extension NuguClient {
    static let speechStateChangedNotification = Notification.Name("com.sktelecom.romaine.speech_state_changed_notification")
}
