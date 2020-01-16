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
public class NuguClient {
    private let container: ComponentContainer
    public weak var delegate: NuguClientDelegate?
    
    /// <#Description#>
    public let wakeUpDetector: KeywordDetector?
    
    /// <#Description#>
    private let inputControlQueue = DispatchQueue(label: "com.sktelecom.romaine.input_control_queue")
    private var inputControlWorkItem: DispatchWorkItem?
    
    /// <#Description#>
    /// - Parameter wakeUpDetector: <#wakeUpDetector description#>
    /// - Parameter capabilityAgentFactory: <#capabilityAgentFactory description#>
    public init(wakeUpDetector: KeywordDetector? = KeywordDetector()) {
        self.wakeUpDetector = wakeUpDetector
        
        container = ComponentContainer()
        
        // Core
        container.register(AuthorizationStoreable.self) { _ in AuthorizationStore.shared }
        container.register(ContextManageable.self) { _ in ContextManager() }
        container.register(AudioStreamable.self) { _ in AudioStream(capacity: 300) }
        container.register(AudioProvidable.self) { _ in MicInputProvider() }
        container.register(MediaPlayerFactory.self) { _ in BuiltInMediaPlayerFactory() }
        container.register(DialogStateAggregatable.self) { _ in DialogStateAggregator() }
        
        container.register(NetworkManageable.self) { [weak self] _ -> NetworkManager in
            let networkManager = NetworkManager()
            
            if let self = self {
                networkManager.add(statusDelegate: self)
                networkManager.add(receiveMessageDelegate: self)
            }
            
            return networkManager
        }
        
        container.register(FocusManageable.self) { [weak self] resolver -> FocusManageable in
            let dialogStateAggregate = resolver.resolve(DialogStateAggregatable.self)!
            let focusManager = FocusManager()
            dialogStateAggregate.add(delegate: focusManager)
            
            if let self = self {
                focusManager.delegate = self
            }
            
            return focusManager
        }

        container.register(PlaySyncManageable.self) { resolver -> PlaySyncManager in
            let contextManager = resolver.resolve(ContextManageable.self)!
            let playSyncManager = PlaySyncManager()
            contextManager.add(provideContextDelegate: playSyncManager)
            
            return playSyncManager
        }

        container.register(StreamDataRoutable.self) { resolver -> StreamDataRouter in
            let networkManager = resolver.resolve(NetworkManageable.self)!
            let streamDataRouter = StreamDataRouter(networkManager: networkManager)
            networkManager.add(receiveMessageDelegate: streamDataRouter)
            
            return streamDataRouter
        }
        
        container.register(DirectiveSequenceable.self) { resolver -> DirectiveSequencer in
            let streamDataRouter = resolver.resolve(StreamDataRoutable.self)!
            let directiveSequencer = DirectiveSequencer(upstreamDataSender: streamDataRouter)
            streamDataRouter.add(delegate: directiveSequencer)
            
            return directiveSequencer
        }
        
        // Capability Agents
        registerBuiltInAgents()
        
        setupAudioStream()
        setupWakeUpDetectorDependency()
    }
    
    private func registerBuiltInAgents() {
        guard let focusManager = container.resolve(FocusManageable.self),
            let streamDataRouter = container.resolve(StreamDataRoutable.self),
            let contextManager = container.resolve(ContextManageable.self),
            let sharedAudioStream = container.resolve(AudioStreamable.self),
            let dialogStateAggregator = container.resolve(DialogStateAggregatable.self),
            let mediaPlayerFactory = container.resolve(MediaPlayerFactory.self),
            let playSyncManager = container.resolve(PlaySyncManageable.self),
            let networkManager = container.resolve(NetworkManageable.self),
            let directiveSequencer = container.resolve(DirectiveSequenceable.self) else {
                return
        }
        
        container.register(ASRAgentProtocol.self) { _ -> ASRAgentProtocol? in
            let asrAgent = ASRAgent(
                focusManager: focusManager,
                channelPriority: .recognition,
                upstreamDataSender: streamDataRouter,
                contextManager: contextManager,
                audioStream: sharedAudioStream,
                dialogStateAggregator: dialogStateAggregator,
                directiveSequencer: directiveSequencer
            )
            
            if let dialogStateAggregator = dialogStateAggregator as? DialogStateAggregator {
                asrAgent.add(delegate: dialogStateAggregator)
            }
            
            return asrAgent
        }
        
        container.register(TTSAgentProtocol.self) { _ -> TTSAgentProtocol? in
            let ttsAgent = TTSAgent(
                focusManager: focusManager,
                channelPriority: .information,
                mediaPlayerFactory: mediaPlayerFactory,
                upstreamDataSender: streamDataRouter,
                playSyncManager: playSyncManager,
                contextManager: contextManager,
                directiveSequencer: directiveSequencer
            )
            
            if let dialogStateAggregator = dialogStateAggregator as? DialogStateAggregator {
                ttsAgent.add(delegate: dialogStateAggregator)
            }
            
            return ttsAgent
        }
        
        container.register(AudioPlayerAgentProtocol.self) { _ in
            return AudioPlayerAgent(
                focusManager: focusManager,
                channelPriority: .content,
                mediaPlayerFactory: mediaPlayerFactory,
                upstreamDataSender: streamDataRouter,
                playSyncManager: playSyncManager,
                contextManager: contextManager,
                directiveSequencer: directiveSequencer
            )
        }
        
        container.register(DisplayAgentProtocol.self) { _ in
            return DisplayAgent(
                upstreamDataSender: streamDataRouter,
                playSyncManager: playSyncManager,
                contextManager: contextManager,
                directiveSequencer: directiveSequencer
            )
        }
        
        container.register(TextAgentProtocol.self) { _ -> TextAgentProtocol? in
            let textAgent = TextAgent(
                contextManager: contextManager,
                upstreamDataSender: streamDataRouter,
                focusManager: focusManager,
                channelPriority: .recognition,
                dialogStateAggregator: dialogStateAggregator
            )
            
            if let dialogStateAggregator = dialogStateAggregator as? DialogStateAggregator {
                textAgent.add(delegate: dialogStateAggregator)
            }
            
            return textAgent
        }
        
        container.register(ExtensionAgentProtocol.self) { _ in
            return ExtensionAgent(
                upstreamDataSender: streamDataRouter,
                contextManager: contextManager,
                directiveSequencer: directiveSequencer
            )
        }
        
        container.register(LocationAgentProtocol.self) { _ in
            return LocationAgent(contextManager: contextManager)
        }
        
        container.register(SystemAgentProtocol.self) { _ in
            return SystemAgent(
                contextManager: contextManager,
                networkManager: networkManager,
                upstreamDataSender: streamDataRouter,
                dialogStateAggregator: dialogStateAggregator,
                directiveSequencer: directiveSequencer
            )
        }
    }
}

// MARK: - Helper functions

extension NuguClient {
    public func addComponent<Component>(_ componentType: Component.Type, option: ComponentKey.Option = .representative, factory: @escaping (ComponentResolver) -> Component?) {
        let additionalComponent = factory(container)
        container.register(componentType, option: option) { _ in additionalComponent }
    }
    
    public func getComponent<Component>(_ componentType: Component.Type) -> Component? {
        return container.resolve(componentType.self)
    }
    
    public func getComponent<Component, Concreate>(_ componentType: Component.Type, concreateType: Concreate.Type, option: ComponentKey.Option = .all) -> Concreate? {
        return container.resolve(componentType.self, concreateType: concreateType, option: option)
    }
    
    public func connect() {
        guard let networkManager = container.resolve(NetworkManageable.self) else {
            return
        }
        
        networkManager.connect()
    }
    
    public func disconnect() {
        guard let networkManager = container.resolve(NetworkManageable.self) else {
            return
        }
        
        networkManager.disconnect()
    }
    
    public func enable() {
        connect()
    }
    
    public func disable() {
        if let focusManager = container.resolve(FocusManageable.self) {
            focusManager.stopForegroundActivity()
        }
        
        if let inputProvider = container.resolve(AudioProvidable.self) {
            inputProvider.stop()
        }
        
        disconnect()
    }
}

// MARK: - Audio Stream Control
extension NuguClient: AudioStreamDelegate {
    private func setupAudioStream() {
        if let audioStream = container.resolve(AudioStreamable.self) as? AudioStream {
            audioStream.delegate = self
        }
    }

    public func audioStreamWillStart() {
        inputControlWorkItem?.cancel()
        inputControlQueue.async { [weak self] in
            guard let sharedAudioStream = self?.container.resolve(AudioStreamable.self),
                self?.container.resolve(AudioProvidable.self)?.isRunning == false else {
                    log.debug("input provider is already started.")
                    return
            }
            
            do {
                try self?.container.resolve(AudioProvidable.self)?.start(streamWriter: sharedAudioStream.makeAudioStreamWriter())
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
            
            guard self.container.resolve(AudioProvidable.self)?.isRunning == true else {
                log.debug("input provider is not running")
                return
            }
            
            self.container.resolve(AudioProvidable.self)?.stop()
            log.debug("input provider is stopped.")
            
        }
        
        inputControlQueue.async(execute: inputControlWorkItem!)
    }
}

// MARK: - Wake Up Detector

extension NuguClient {
    private func setupWakeUpDetectorDependency() {
        guard let wakeUpDetector = wakeUpDetector else { return }

        if let sharedAudioStream = container.resolve(AudioStreamable.self) {
            wakeUpDetector.audioStream = sharedAudioStream
        }

        if let contextManager = container.resolve(ContextManageable.self) {
            contextManager.add(provideContextDelegate: wakeUpDetector)
        }
    }
}

// MARK: - FocusManagerDelegate

extension NuguClient: FocusDelegate {
    public func focusShouldAcquire() -> Bool {
        delegate?.nuguClientWillRequireAudioSession() == true
    }
    
    public func focusShouldRelease() {
        delegate?.nuguClientDidReleaseAudioSession()
    }
}

// MARK: - Delegates releated Network

extension NuguClient: NetworkStatusDelegate {
    public func networkStatusDidChange(_ status: NetworkStatus) {
        delegate?.nuguClientConnectionStatusChanged(status: status)
    }
}

extension NuguClient: ReceiveMessageDelegate {
    public func receiveMessageDidReceive(header: [String: String], body: Data) {
        delegate?.nuguClientDidReceiveMessage(header: header, body: body)
    }
}
