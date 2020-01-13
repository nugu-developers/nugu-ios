//
//  NuguClient.swift
//  NuguClientKit
//
//  Created by MinChul Lee on 09/04/2019.
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
import NuguInterface

/// <#Description#>
public class NuguClient: NuguClientContainer {
    
    // MARK: NuguClientContainer
    
    /// <#Description#>
    public let authorizationStore: AuthorizationStoreable
    /// <#Description#>
    public let focusManager: FocusManageable
    /// <#Description#>
    public let networkManager: NetworkManageable
    /// <#Description#>
    public let dialogStateAggregator: DialogStateAggregatable
    /// <#Description#>
    public let contextManager: ContextManageable
    /// <#Description#>
    public let playSyncManager: PlaySyncManageable
    /// <#Description#>
    public let directiveSequencer: DirectiveSequenceable
    /// <#Description#>
    public let streamDataRouter: StreamDataRoutable
    /// <#Description#>
    public let mediaPlayerFactory: MediaPlayerFactory
    /// <#Description#>
    public let sharedAudioStream: AudioStreamable
    /// <#Description#>
    public let inputProvider: AudioProvidable
    /// <#Description#>
    public let endPointDetector: EndPointDetectable
    
    /// <#Description#>
    public let wakeUpDetector: KeywordDetector?
    
    private let capabilityAgentFactory: CapabilityAgentFactory
    private let inputControlQueue = DispatchQueue(label: "com.sktelecom.romaine.input_control_queue")
    private var inputControlWorkItem: DispatchWorkItem?
    
    // MARK: CapabilityAgents
    
    /// <#Description#>
    public private(set) lazy var systemAgent: SystemAgentProtocol = SystemAgent(
        contextManager: contextManager,
        networkManager: networkManager,
        upstreamDataSender: streamDataRouter,
        dialogStateAggregator: dialogStateAggregator,
        directiveSequencer: directiveSequencer
    )
    
    /// <#Description#>
    public private(set) lazy var asrAgent: ASRAgentProtocol? = capabilityAgentFactory.makeASRAgent(container: self)
    /// <#Description#>
    public private(set) lazy var ttsAgent: TTSAgentProtocol? = capabilityAgentFactory.makeTTSAgent(container: self)
    /// <#Description#>
    public private(set) lazy var audioPlayerAgent: AudioPlayerAgentProtocol? = capabilityAgentFactory.makeAudioPlayerAgent(container: self)
    /// <#Description#>
    public private(set) lazy var displayAgent: DisplayAgentProtocol? = capabilityAgentFactory.makeDisplayAgent(container: self)
    /// <#Description#>
    public private(set) lazy var textAgent: TextAgentProtocol? = capabilityAgentFactory.makeTextAgent(container: self)
    /// <#Description#>
    public private(set) lazy var extensionAgent: ExtensionAgentProtocol? = capabilityAgentFactory.makeExtensionAgent(container: self)
    /// <#Description#>
    public private(set) lazy var locationAgent: LocationAgentProtocol? = capabilityAgentFactory.makeLocationAgent(container: self)
    
    /// <#Description#>
    /// - Parameter authorizationManager: <#authorizationManager description#>
    /// - Parameter focusManager: <#focusManager description#>
    /// - Parameter networkManager: <#networkManager description#>
    /// - Parameter contextManager: <#contextManager description#>
    /// - Parameter playSyncManager: <#playSyncManager description#>
    /// - Parameter sharedAudioStream: <#sharedAudioStream description#>
    /// - Parameter inputProvider: <#inputProvider description#>
    /// - Parameter endPointDetector: <#endPointDetector description#>
    /// - Parameter wakeUpDetector: <#wakeUpDetector description#>
    /// - Parameter mediaPlayerFactory: <#mediaPlayerFactory description#>
    /// - Parameter capabilityAgentFactory: <#capabilityAgentFactory description#>
    public init(
        authorizationStore: AuthorizationStoreable = AuthorizationStore.shared,
        focusManager: FocusManageable = FocusManager(),
        networkManager: NetworkManageable = NetworkManager(),
        contextManager: ContextManageable = ContextManager(),
        playSyncManager: PlaySyncManageable = PlaySyncManager(),
        sharedAudioStream: AudioStreamable = AudioStream(capacity: 300),
        inputProvider: AudioProvidable = MicInputProvider(),
        endPointDetector: EndPointDetectable = EndPointDetector(),
        wakeUpDetector: KeywordDetector? = KeywordDetector(),
        mediaPlayerFactory: MediaPlayerFactory = BuiltInMediaPlayerFactory(),
        capabilityAgentFactory: CapabilityAgentFactory
    ) {
        self.authorizationStore = authorizationStore
        self.focusManager = focusManager
        self.networkManager = networkManager
        self.contextManager = contextManager
        self.playSyncManager = playSyncManager
        self.mediaPlayerFactory = mediaPlayerFactory
        self.sharedAudioStream = sharedAudioStream
        self.inputProvider = inputProvider
        self.endPointDetector = endPointDetector
        self.wakeUpDetector = wakeUpDetector
        self.capabilityAgentFactory = capabilityAgentFactory
        
        let dialogStateAggregator = DialogStateAggregator()
        
        self.dialogStateAggregator = dialogStateAggregator
        self.streamDataRouter = StreamDataRouter(networkManager: networkManager)
        self.directiveSequencer = DirectiveSequencer(upstreamDataSender: streamDataRouter)
        
        asrAgent?.add(delegate: dialogStateAggregator)
        textAgent?.add(delegate: dialogStateAggregator)
        ttsAgent?.add(delegate: dialogStateAggregator)
        
        setupDependencies()
    }
}

// MARK: - AudioStreamDelegate

extension NuguClient: AudioStreamDelegate {
    public func audioStreamWillStart() {
        inputControlWorkItem?.cancel()
        inputControlQueue.async { [weak self] in
            guard let sharedAudioStream = self?.sharedAudioStream,
                self?.inputProvider.isRunning == false else {
                    log.debug("input provider is already started.")
                    return
            }
            
            do {
                try self?.inputProvider.start(streamWriter: sharedAudioStream.makeAudioStreamWriter())
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
            log.debug("input provider is stopped.")
            
        }
        
        inputControlQueue.asyncAfter(deadline: .now() + 3, execute: inputControlWorkItem!)
    }
}
