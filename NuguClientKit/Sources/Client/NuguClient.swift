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

public class NuguClient {
    private weak var delegate: NuguClientDelegate?
    
    // core
    public let contextManager: ContextManageable
    public let focusManager: FocusManageable
    public let streamDataRouter: StreamDataRoutable
    public let directiveSequencer: DirectiveSequenceable
    public let playSyncManager: PlaySyncManageable
    public let systemAgent: SystemAgentProtocol
    
    // default agents
    public let dialogStateAggregator: DialogStateAggregator
    public let asrAgent: ASRAgentProtocol
    public let ttsAgent: TTSAgentProtocol
    public let textAgent: TextAgentProtocol
    public let audioPlayerAgent: AudioPlayerAgentProtocol
    public let soundAgent: SoundAgentProtocol

    // additional agents
    public lazy var chipsAgent: ChipsAgentProtocol = ChipsAgent(
        contextManager: contextManager,
        directiveSequencer: directiveSequencer
    )
    
    public lazy var displayAgent: DisplayAgentProtocol = DisplayAgent(
        upstreamDataSender: streamDataRouter,
        playSyncManager: playSyncManager,
        contextManager: contextManager,
        directiveSequencer: directiveSequencer
    )
    
    public lazy var extensionAgent: ExtensionAgentProtocol = ExtensionAgent(
        upstreamDataSender: streamDataRouter,
        contextManager: contextManager,
        directiveSequencer: directiveSequencer
    )
    
    public lazy var locationAgent: LocationAgentProtocol = LocationAgent(contextManager: contextManager)
    
    /**
     Audio input source
     
     You can change this property when you want to use the audio data stream from other sources.
     - Note: Default audio source is hardware mic.
     */
    public var inputProvider: AudioProvidable = MicInputProvider()
    
    /**
     Audio stream made from ring buffer.
     
     - Note: default capacity of ring is 300.
     */
    public var sharedAudioStream: AudioStreamable = AudioStream(capacity: 300)
    
    // keywordDetector
    public private(set) lazy var keywordDetector: KeywordDetector = {
        let keywordDetector =  KeywordDetector()
        keywordDetector.audioStream = sharedAudioStream
        contextManager.add(delegate: keywordDetector)
        
        return keywordDetector
    }()
    
    public init(delegate: NuguClientDelegate) {
        self.delegate = delegate
        
        // core
        contextManager = ContextManager()
        focusManager = FocusManager()
        directiveSequencer = DirectiveSequencer()
        streamDataRouter = StreamDataRouter(directiveSequencer: directiveSequencer)
        playSyncManager = PlaySyncManager(contextManager: contextManager)
        systemAgent = SystemAgent(contextManager: contextManager,
                                  streamDataRouter: streamDataRouter,
                                  directiveSequencer: directiveSequencer)
        
        // dialog
        asrAgent = ASRAgent(focusManager: focusManager,
                            upstreamDataSender: streamDataRouter,
                            contextManager: contextManager,
                            audioStream: sharedAudioStream,
                            directiveSequencer: directiveSequencer)
        
        ttsAgent = TTSAgent(focusManager: focusManager,
                            upstreamDataSender: streamDataRouter,
                            playSyncManager: playSyncManager,
                            contextManager: contextManager,
                            directiveSequencer: directiveSequencer)

        textAgent = TextAgent(contextManager: contextManager,
                              upstreamDataSender: streamDataRouter,
                              directiveSequencer: directiveSequencer)
        
        dialogStateAggregator = DialogStateAggregator()
        asrAgent.add(delegate: dialogStateAggregator)
        ttsAgent.add(delegate: dialogStateAggregator)
        
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

        // setup additional roles
        setupAudioStream()
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

// MARK: - Audio Stream Control

extension NuguClient: AudioStreamDelegate {
    private func setupAudioStream() {
        if let audioStream = sharedAudioStream as? AudioStream {
            audioStream.delegate = self
        }
    }
    
    public func audioStreamWillStart() {
        log.debug("")
        guard inputProvider.isRunning == false else {
            log.debug("input provider is already started.")
            return
        }
        
        delegate?.nuguClientWillOpenInputSource()
        
        do {
            try inputProvider.start(streamWriter: self.sharedAudioStream.makeAudioStreamWriter())
            
            log.debug("input provider is started.")
        } catch {
            log.debug("input provider failed to start: \(error)")
        }
    }
    
    public func audioStreamDidStop() {
        log.debug("")
        guard self.inputProvider.isRunning == true else {
            log.debug("input provider is not running")
            return
        }
        
        self.inputProvider.stop()
        self.delegate?.nuguClientDidCloseInputSource()
        log.debug("input provider is stopped.")
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
    
    public func dialogStateDidChange(_ state: DialogState, expectSpeech: ASRExpectSpeech?) {
        switch state {
        case .idle:
            playSyncManager.resetTimer(property: PlaySyncProperty(layerType: .info, contextType: .display))
        case .listening:
            playSyncManager.cancelTimer(property: PlaySyncProperty(layerType: .info, contextType: .display))
        default:
            break
        }
    }
}

// MARK: - StreamDataDelegate

extension NuguClient: StreamDataDelegate {
    private func setupStreamDataRouter() {
        streamDataRouter.delegate = self
    }
    
    public func streamDataDidReceive(direcive: Downstream.Directive) {
        delegate?.nuguClientDidReceive(direcive: direcive)
    }
    
    public func streamDataDidReceive(attachment: Downstream.Attachment) {
        delegate?.nuguClientDidReceive(attachment: attachment)
    }
    
    public func streamDataDidSend(event: Upstream.Event, error: Error?) {
        delegate?.nuguClientDidSend(event: event, error: error)
    }
    
    public func streamDataDidSend(attachment: Upstream.Attachment, error: Error?) {
        delegate?.nuguClientDidSend(attachment: attachment, error: error)
    }
}
