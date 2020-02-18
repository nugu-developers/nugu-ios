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
    public let networkManager: NetworkManageable
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
        networkManager = NetworkManager()
        streamDataRouter = StreamDataRouter(networkManager: networkManager)
        directiveSequencer = DirectiveSequencer(streamDataRouter: streamDataRouter)
        playSyncManager = PlaySyncManager(contextManager: contextManager)
        systemAgent = SystemAgent(contextManager: contextManager,
                                  networkManager: networkManager,
                                  upstreamDataSender: streamDataRouter,
                                  directiveSequencer: directiveSequencer)
        
        // dialog
        asrAgent = ASRAgent(focusManager: focusManager,
                            channelPriority: .recognition,
                            upstreamDataSender: streamDataRouter,
                            contextManager: contextManager,
                            audioStream: sharedAudioStream,
                            directiveSequencer: directiveSequencer)
        
        ttsAgent = TTSAgent(focusManager: focusManager,
                            channelPriority: .information,
                            upstreamDataSender: streamDataRouter,
                            playSyncManager: playSyncManager,
                            contextManager: contextManager,
                            directiveSequencer: directiveSequencer)

        textAgent = TextAgent(contextManager: contextManager,
                              upstreamDataSender: streamDataRouter,
                              focusManager: focusManager,
                              channelPriority: .recognition)
        
        dialogStateAggregator = DialogStateAggregator()
        asrAgent.add(delegate: dialogStateAggregator)
        ttsAgent.add(delegate: dialogStateAggregator)
        textAgent.add(delegate: dialogStateAggregator)
        
        // audio player
        audioPlayerAgent = AudioPlayerAgent(
            focusManager: focusManager,
            channelPriority: .content,
            upstreamDataSender: streamDataRouter,
            playSyncManager: playSyncManager,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer
        )

        // setup additional roles
        setupAudioStream()
        setupAuthorizationStore()
        setupAudioSessionRequester()
        setupNetworkInfoFoward()
    }
}
    
// MARK: - Helper functions

public extension NuguClient {
    func connect() {
        networkManager.connect()
    }
    
    func disconnect() {
        networkManager.disconnect()
    }
    
    func enable() {
        connect()
    }
    
    func disable() {
        focusManager.stopForegroundActivity()
        inputProvider.stop()
        
        disconnect()
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

// MARK: - Delegates releated Network

extension NuguClient: NetworkStatusDelegate, ReceiveMessageDelegate {
    private func setupNetworkInfoFoward() {
        networkManager.add(receiveMessageDelegate: self)
        networkManager.add(statusDelegate: self)
    }
    
    public func networkStatusDidChange(_ status: NetworkStatus) {
        delegate?.nuguClientConnectionStatusChanged(status: status)
    }
    
    public func receiveMessageDidReceive(header: [String: String], body: Data) {
        delegate?.nuguClientDidReceiveMessage(header: header, body: body)
    }
}
