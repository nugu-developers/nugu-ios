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

public class NuguClient: NuguClientContainer {
    public let authorizationManager: AuthorizationManageable
    public let focusManager: FocusManageable
    public let networkManager: NetworkManageable
    public let dialogStateAggregator: DialogStateAggregatable
    public let contextManager: ContextManageable
    public let playSyncManager: PlaySyncManageable
    public let directiveSequencer: DirectiveSequenceable
    public let downStreamDataTimeoutPreprocessor: DownStreamDataTimeoutPreprocessor
    public let downStreamDataInterpreter: DownStreamDataInterpretable
    public let mediaPlayerFactory: MediaPlayableFactory
    public let sharedAudioStream: AudioStreamable
    public let inputProvider: AudioProvidable
    public let endPointDetector: EndPointDetectable
    public let wakeUpDetector: KeywordDetector?
    
    private let capabilityAgentFactory: CapabilityAgentFactory
    private let inputControlQueue = DispatchQueue(label: "com.sktelecom.romaine.input_control_queue")
    private var inputControlWorkItem: DispatchWorkItem?
    
    public private(set) lazy var systemAgent: SystemAgentProtocol = SystemAgent(
        contextManager: contextManager,
        networkManager: networkManager
    )
    
    public private(set) lazy var asrAgent: ASRAgentProtocol? = capabilityAgentFactory.makeASRAgent(container: self)
    public private(set) lazy var ttsAgent: TTSAgentProtocol? = capabilityAgentFactory.makeTTSAgent(container: self)
    public private(set) lazy var audioPlayerAgent: AudioPlayerAgentProtocol? = capabilityAgentFactory.makeAudioPlayerAgent(container: self)
    public private(set) lazy var displayAgent: DisplayAgentProtocol? = capabilityAgentFactory.makeDisplayAgent(container: self)
    public private(set) lazy var textAgent: TextAgentProtocol? = capabilityAgentFactory.makeTextAgent(container: self)
    public private(set) lazy var extensionAgent: ExtensionAgentProtocol? = capabilityAgentFactory.makeExtensionAgent(container: self)
    public private(set) lazy var locationAgent: LocationAgentProtocol? = capabilityAgentFactory.makeLocationAgent(container: self)
    
    public init(
        authorizationManager: AuthorizationManageable = AuthorizationManager.shared,
        focusManager: FocusManageable = FocusManager(),
        networkManager: NetworkManageable = NetworkManager(),
        dialogStateAggregator: DialogStateAggregatable = DialogStateAggregator(),
        contextManager: ContextManageable = ContextManager(),
        playSyncManager: PlaySyncManageable = PlaySyncManager(),
        downStreamDataInterpreter: DownStreamDataInterpretable = DownStreamDataInterpreter(),
        mediaPlayerFactory: MediaPlayableFactory = BuiltInMediaPlayerFactory(),
        sharedAudioStream: AudioStreamable = AudioStream(capacity: 300),
        inputProvider: AudioProvidable = MicInputProvider(),
        endPointDetector: EndPointDetectable = EndPointDetector(),
        wakeUpDetector: KeywordDetector? = KeywordDetector(),
        capabilityAgentFactory: CapabilityAgentFactory
    ) {
        self.authorizationManager = authorizationManager
        self.focusManager = focusManager
        self.networkManager = networkManager
        self.dialogStateAggregator = dialogStateAggregator
        self.contextManager = contextManager
        self.playSyncManager = playSyncManager
        self.directiveSequencer = DirectiveSequencer(messageSender: networkManager)
        self.downStreamDataTimeoutPreprocessor = DownStreamDataTimeoutPreprocessor()
        self.downStreamDataInterpreter = downStreamDataInterpreter
        self.mediaPlayerFactory = mediaPlayerFactory
        self.sharedAudioStream = sharedAudioStream
        self.inputProvider = inputProvider
        self.endPointDetector = endPointDetector
        self.wakeUpDetector = wakeUpDetector
        self.capabilityAgentFactory = capabilityAgentFactory
        
        setupDependencies()
    }
}

// MARK: - Authorization

public extension NuguClient {
    /// <#Description#>
    var accessToken: String? {
        get {
            return authorizationManager.authorizationPayload?.accessToken
        } set {
            guard let newAccessToken = newValue else {
                authorizationManager.authorizationPayload = nil
                return
            }
            
            authorizationManager.authorizationPayload = AuthorizationPayload(accessToken: newAccessToken)
        }
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
