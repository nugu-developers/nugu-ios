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
    private weak var delegate: NuguClientDelegate?
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var streamDataDirectiveDidReceive: Any?
    private var streamDataAttachmentDidReceive: Any?
    private var streamDataEventWillSend: Any?
    private var streamDataEventDidSend: Any?
    private var streamDataAttachmentDidSent: Any?
    private var dialogStateObserver: Any?
    
    // core
    /// <#Description#>
    public let contextManager: ContextManageable
    /// <#Description#>
    public let focusManager: FocusManageable
    /// <#Description#>
    public let streamDataRouter: StreamDataRoutable
    /// <#Description#>
    public let directiveSequencer: DirectiveSequenceable
    /// <#Description#>
    public let playSyncManager: PlaySyncManageable
    /// <#Description#>
    public let dialogAttributeStore: DialogAttributeStoreable
    /// <#Description#>
    public let sessionManager: SessionManageable
    /// <#Description#>
    public let systemAgent: SystemAgentProtocol
    /// <#Description#>
    public let interactionControlManager: InteractionControlManageable
    
    // default agents
    /// <#Description#>
    public let dialogStateAggregator: DialogStateAggregator
    /// <#Description#>
    public let asrAgent: ASRAgentProtocol
    /// <#Description#>
    public let ttsAgent: TTSAgentProtocol
    /// <#Description#>
    public let textAgent: TextAgentProtocol
    /// <#Description#>
    public let audioPlayerAgent: AudioPlayerAgentProtocol
    /// <#Description#>
    public let soundAgent: SoundAgentProtocol
    /// <#Description#>
    public let sessionAgent: SessionAgentProtocol
    /// <#Description#>
    public let chipsAgent: ChipsAgentProtocol
    /// <#Description#>
    public let utilityAgent: UtilityAgentProtocol

    // additional agents
    /// <#Description#>
    public lazy var displayAgent: DisplayAgentProtocol = DisplayAgent(
        upstreamDataSender: streamDataRouter,
        playSyncManager: playSyncManager,
        contextManager: contextManager,
        directiveSequencer: directiveSequencer,
        sessionManager: sessionManager,
        interactionControlManager: interactionControlManager
    )
    
    /// <#Description#>
    public lazy var extensionAgent: ExtensionAgentProtocol = ExtensionAgent(
        upstreamDataSender: streamDataRouter,
        contextManager: contextManager,
        directiveSequencer: directiveSequencer
    )
    
    /// <#Description#>
    public lazy var locationAgent: LocationAgentProtocol = LocationAgent(contextManager: contextManager)
    
    /// <#Description#>
    public lazy var phoneCallAgent: PhoneCallAgentProtocol = PhoneCallAgent(
        directiveSequencer: directiveSequencer,
        contextManager: contextManager,
        upstreamDataSender: streamDataRouter,
        interactionControlManager: interactionControlManager
    )
    
    /// <#Description#>
    public lazy var mediaPlayerAgent: MediaPlayerAgentProtocol = MediaPlayerAgent(
        directiveSequencer: directiveSequencer,
        contextManager: contextManager,
        upstreamDataSender: streamDataRouter
    )
    
    /// <#Description#>
    public private(set) lazy var keywordDetector: KeywordDetector = KeywordDetector(contextManager: contextManager)

    public var speechRecognizerAggregator: SpeechRecognizerAggregatable?
    public var audioSessionManager: AudioSessionManageable?
    
    private let backgroundFocusHolder: BackgroundFocusHolder
    
    /// <#Description#>
    /// - Parameter delegate: <#delegate description#>
    public init(delegate: NuguClientDelegate) {
        self.delegate = delegate
        
        // core
        contextManager = ContextManager()
        directiveSequencer = DirectiveSequencer()
        focusManager = FocusManager()
        streamDataRouter = StreamDataRouter(directiveSequencer: directiveSequencer)
        playSyncManager = PlaySyncManager(contextManager: contextManager)
        dialogAttributeStore = DialogAttributeStore()
        sessionManager = SessionManager()
        interactionControlManager = InteractionControlManager()
        
        systemAgent = SystemAgent(contextManager: contextManager,
                                  streamDataRouter: streamDataRouter,
                                  directiveSequencer: directiveSequencer)
        
        // dialog
        asrAgent = ASRAgent(
            focusManager: focusManager,
            upstreamDataSender: streamDataRouter,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer,
            dialogAttributeStore: dialogAttributeStore,
            sessionManager: sessionManager,
            playSyncManager: playSyncManager,
            interactionControlManager: interactionControlManager
        )
        
        ttsAgent = TTSAgent(
            focusManager: focusManager,
            upstreamDataSender: streamDataRouter,
            playSyncManager: playSyncManager,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer
        )
        
        textAgent = TextAgent(
            contextManager: contextManager,
            upstreamDataSender: streamDataRouter,
            directiveSequencer: directiveSequencer,
            dialogAttributeStore: dialogAttributeStore,
            interactionControlManager: interactionControlManager
        )
        
        chipsAgent = ChipsAgent(
            contextManager: contextManager,
            directiveSequencer: directiveSequencer
        )
        
        dialogStateAggregator = DialogStateAggregator(
            sessionManager: sessionManager,
            interactionControlManager: interactionControlManager,
            focusManager: focusManager,
            asrAgent: asrAgent,
            ttsAgent: ttsAgent,
            chipsAgent: chipsAgent
        )
        
        // audio player
        audioPlayerAgent = AudioPlayerAgent(
            focusManager: focusManager,
            upstreamDataSender: streamDataRouter,
            playSyncManager: playSyncManager,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer
        )
        
        soundAgent = SoundAgent(
            focusManager: focusManager,
            upstreamDataSender: streamDataRouter,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer
        )
        
        sessionAgent = SessionAgent(
            contextManager: contextManager,
            directiveSequencer: directiveSequencer,
            sessionManager: sessionManager
        )
        
        utilityAgent = UtilityAgent(
            directiveSequencer: directiveSequencer,
            contextManager: contextManager
        )
        
        backgroundFocusHolder = BackgroundFocusHolder(
            focusManager: focusManager,
            directiveSequener: directiveSequencer,
            streamDataRouter: streamDataRouter,
            dialogStateAggregator: dialogStateAggregator
        )

        // setup additional roles
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
        delegate?.nuguClientWillRequireAudioSession() == true
    }
    
    public func focusShouldRelease() {
        delegate?.nuguClientDidReleaseAudioSession()
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
