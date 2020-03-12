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
    public weak var delegate: NuguClientDelegate?
    
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

    // additional agents
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
        contextManager.add(provideContextDelegate: keywordDetector)
        
        return keywordDetector
    }()
    
    // private
    private let inputControlQueue = DispatchQueue(label: "com.sktelecom.romaine.input_control_queue")
    private var inputControlWorkItem: DispatchWorkItem?
    
    public init() {
        // core
        contextManager = ContextManager()
        focusManager = FocusManager()
        streamDataRouter = StreamDataRouter()
        directiveSequencer = DirectiveSequencer(streamDataRouter: streamDataRouter)
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
                              focusManager: focusManager)
        
        dialogStateAggregator = DialogStateAggregator()
        asrAgent.add(delegate: dialogStateAggregator)
        ttsAgent.add(delegate: dialogStateAggregator)
        textAgent.add(delegate: dialogStateAggregator)
        
        // audio player
        audioPlayerAgent = AudioPlayerAgent(
            focusManager: focusManager,
            upstreamDataSender: streamDataRouter,
            playSyncManager: playSyncManager,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer
        )

        // setup additional roles
        setupAudioStream()
        setupAuthorizationStore()
        setupAudioSessionRequester()
    }
}
    
// MARK: - Helper functions

public extension NuguClient {
    func startReceiveServerInitiatedDirective(completion: ((Result<StreamDataResult, Error>) -> Void)? = nil) {
        streamDataRouter.startReceiveServerInitiatedDirective(completion: completion)
    }
    
    func stopReceiveServerInitiatedDirective() {
        streamDataRouter.stopReceiveServerInitiatedDirective()
    }
    
    func setChargingFreeUrl(_ url: String) {
          streamDataRouter.chargingFreeUrl = url
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
        inputControlWorkItem?.cancel()
        inputControlQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard self.inputProvider.isRunning == false else {
                log.debug("input provider is already started.")
                return
            }

            self.delegate?.nuguClientWillOpenInputSource()
            
            do {
                try self.inputProvider.start(streamWriter: self.sharedAudioStream.makeAudioStreamWriter())

                log.debug("input provider is started.")
            } catch {
                log.debug("input provider failed to start: \(error)")
            }
        }
    }
    
    public func audioStreamDidStop() {
        inputControlWorkItem?.cancel()
        inputControlWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            guard self.inputControlWorkItem?.isCancelled == false else {
                log.debug("Stopping input provider is cancelled")
                return
            }
            
            guard self.inputProvider.isRunning == true else {
                log.debug("input provider is not running")
                return
            }
            
            self.inputProvider.stop()
            self.delegate?.nuguClientDidCloseInputSource()
            log.debug("input provider is stopped.")
        }
        inputControlQueue.async(execute: inputControlWorkItem!)
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
    public func setupAudioSessionRequester() {
        focusManager.delegate = self
    }
    
    public func focusShouldAcquire() -> Bool {
        delegate?.nuguClientWillRequireAudioSession() == true
    }
    
    public func focusShouldRelease() {
        delegate?.nuguClientDidReleaseAudioSession()
    }
}
