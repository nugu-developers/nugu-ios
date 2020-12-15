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

import NuguCore
import NuguAgents

/// <#Description#>
public class NuguClient {
    private weak var delegate: NuguClientDelegate?
    
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
    public private(set) lazy var keywordDetector: KeywordDetector = {
        let keywordDetector =  KeywordDetector()
        contextManager.add(delegate: keywordDetector)
        
        return keywordDetector
    }()
    
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
            dialogAttributeStore: dialogAttributeStore
        )
        
        chipsAgent = ChipsAgent(
            contextManager: contextManager,
            directiveSequencer: directiveSequencer
        )
        
        dialogStateAggregator = DialogStateAggregator(
            sessionManager: sessionManager,
            interactionControlManager: interactionControlManager,
            focusManager: focusManager
        )
        asrAgent.add(delegate: dialogStateAggregator)
        ttsAgent.add(delegate: dialogStateAggregator)
        chipsAgent.add(delegate: dialogStateAggregator)
        
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
        
        backgroundFocusHolder = BackgroundFocusHolder(
            focusManager: focusManager,
            directiveSequener: directiveSequencer,
            streamDataRouter: streamDataRouter,
            dialogStateAggregator: dialogStateAggregator
        )

        // setup additional roles
        setupAuthorizationStore()
        setupAudioSessionRequester()
        setupDialogStateAggregator()
        setupStreamDataRouter()
    }
}
    
// MARK: - Helper functions

public extension NuguClient {
    func startReceiveServerInitiatedDirective(completion: ((StreamDataState) -> Void)? = nil) {
        streamDataRouter.startReceiveServerInitiatedDirective(completion: completion)
    }
    
    func stopReceiveServerInitiatedDirective() {
        streamDataRouter.stopReceiveServerInitiatedDirective()
    }
}

// MARK: - Authorization

extension NuguClient: AuthorizationStoreDelegate {
    private func setupAuthorizationStore() {
        AuthorizationStore.shared.delegate = self
    }
    
    public func authorizationStoreRequestAccessToken() -> String? {
        return delegate?.nuguClientRequestAccessToken()
    }
}

// MARK: - FocusManagerDelegate

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

// MARK: - DialogStateDelegate

extension NuguClient: DialogStateDelegate {
    private func setupDialogStateAggregator() {
        dialogStateAggregator.add(delegate: self)
    }
    
    public func dialogStateDidChange(_ state: DialogState, isMultiturn: Bool, chips: [ChipsAgentItem.Chip]?, sessionActivated: Bool) {
        switch state {
        case .idle:
            playSyncManager.resumeTimer(property: PlaySyncProperty(layerType: .info, contextType: .display))
        case .listening:
            playSyncManager.pauseTimer(property: PlaySyncProperty(layerType: .info, contextType: .display))
        default:
            break
        }
    }
}

// MARK: - StreamDataDelegate

extension NuguClient: StreamDataDelegate {
    private func setupStreamDataRouter() {
        streamDataRouter.add(delegate: self)
    }
    
    public func streamDataDidReceive(direcive: Downstream.Directive) {
        delegate?.nuguClientDidReceive(direcive: direcive)
    }
    
    public func streamDataDidReceive(attachment: Downstream.Attachment) {
        delegate?.nuguClientDidReceive(attachment: attachment)
    }
    
    public func streamDataWillSend(event: Upstream.Event) {
        delegate?.nuguClientWillSend(event: event)
    }
    
    public func streamDataDidSend(event: Upstream.Event, error: Error?) {
        delegate?.nuguClientDidSend(event: event, error: error)
    }
    
    public func streamDataDidSend(attachment: Upstream.Attachment, error: Error?) {
        delegate?.nuguClientDidSend(attachment: attachment, error: error)
    }
}
