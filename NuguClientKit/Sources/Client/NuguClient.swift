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
import NuguAgents

public class NuguClient {
    private let coreContainer: ComponentContainer
    private let additionalContainer: ComponentContainer
    public weak var delegate: NuguClientDelegate?
    
    private let inputControlQueue = DispatchQueue(label: "com.sktelecom.romaine.input_control_queue")
    private var inputControlWorkItem: DispatchWorkItem?
    
    public init() {
        coreContainer = ComponentContainer()
        additionalContainer = ComponentContainer()
        
        // Core Components
        registerCoreComponents()
        
        // dialog state aggregator
        registerDialogStateAggregator()
        
        // Keyword Detector
        registerKeywordDetector()
        
        // Capability Agents
        registerBuiltInAgents()
        
        // setup additional roles
        setupAudioStream()
        setupAuthorizationStore()
    }
    
    private func registerCoreComponents() {
        coreContainer.register(ContextManageable.self) { _ in ContextManager() }
        coreContainer.register(AudioStreamable.self) { _ in AudioStream(capacity: 300) }
        coreContainer.register(AudioProvidable.self) { _ in MicInputProvider() }
        
        coreContainer.register(FocusManageable.self) { [weak self] _ -> FocusManager in
            let focusManager = FocusManager()
            
            if let self = self {
                focusManager.delegate = self
            }
            
            return focusManager
        }
        
        coreContainer.register(NetworkManageable.self) { [weak self] _ -> NetworkManager in
            let networkManager = NetworkManager()
            
            if let self = self {
                networkManager.add(statusDelegate: self)
                networkManager.add(receiveMessageDelegate: self)
            }
            
            return networkManager
        }
        
        coreContainer.register(PlaySyncManageable.self) { resolver -> PlaySyncManager in
            let contextManager = resolver.resolve(ContextManageable.self)!
            let playSyncManager = PlaySyncManager()
            contextManager.add(provideContextDelegate: playSyncManager)
            
            return playSyncManager
        }

        coreContainer.register(StreamDataRoutable.self) { resolver -> StreamDataRouter in
            let networkManager = resolver.resolve(NetworkManageable.self)!
            let streamDataRouter = StreamDataRouter(networkManager: networkManager)
            networkManager.add(receiveMessageDelegate: streamDataRouter)
            
            return streamDataRouter
        }
        
        coreContainer.register(DirectiveSequenceable.self) { resolver -> DirectiveSequencer in
            let streamDataRouter = resolver.resolve(StreamDataRoutable.self)!
            let directiveSequencer = DirectiveSequencer(upstreamDataSender: streamDataRouter)
            streamDataRouter.add(delegate: directiveSequencer)
            
            return directiveSequencer
        }
    }
    
    private func registerDialogStateAggregator() {
        addComponent(DialogStateAggregator.self) { _ in DialogStateAggregator() }
    }
    
    private func registerKeywordDetector() {
        addComponent(KeywordDetector.self) { (resolver) -> KeywordDetector in
            let keywordDetector = KeywordDetector()
            
            if let sharedAudioStream = resolver.resolve(AudioStreamable.self) {
                keywordDetector.audioStream = sharedAudioStream
            }

            if let contextManager = resolver.resolve(ContextManageable.self) {
                contextManager.add(provideContextDelegate: keywordDetector)
            }
            
            return keywordDetector
        }
    }
    
    private func registerBuiltInAgents() {
        guard let focusManager = coreContainer.resolve(FocusManageable.self),
            let streamDataRouter = coreContainer.resolve(StreamDataRoutable.self),
            let contextManager = coreContainer.resolve(ContextManageable.self),
            let sharedAudioStream = coreContainer.resolve(AudioStreamable.self),
            let playSyncManager = coreContainer.resolve(PlaySyncManageable.self),
            let networkManager = coreContainer.resolve(NetworkManageable.self),
            let directiveSequencer = coreContainer.resolve(DirectiveSequenceable.self) else {
                return
        }
        
        addComponent(ASRAgentProtocol.self) { resolver -> ASRAgentProtocol? in
            let asrAgent = ASRAgent(
                focusManager: focusManager,
                channelPriority: .recognition,
                upstreamDataSender: streamDataRouter,
                contextManager: contextManager,
                audioStream: sharedAudioStream,
                directiveSequencer: directiveSequencer
            )
            
            asrAgent.add(delegate: resolver.resolve(DialogStateAggregator.self)!)
            
            return asrAgent
        }
        
        addComponent(TTSAgentProtocol.self) { resolver -> TTSAgentProtocol? in
            let ttsAgent = TTSAgent(
                focusManager: focusManager,
                channelPriority: .information,
                upstreamDataSender: streamDataRouter,
                playSyncManager: playSyncManager,
                contextManager: contextManager,
                directiveSequencer: directiveSequencer
            )
            
            ttsAgent.add(delegate: resolver.resolve(DialogStateAggregator.self)!)
            
            return ttsAgent
        }
        
        addComponent(AudioPlayerAgentProtocol.self) { _ in
            return AudioPlayerAgent(
                focusManager: focusManager,
                channelPriority: .content,
                upstreamDataSender: streamDataRouter,
                playSyncManager: playSyncManager,
                contextManager: contextManager,
                directiveSequencer: directiveSequencer
            )
        }
        
        addComponent(DisplayAgentProtocol.self) { _ in
            return DisplayAgent(
                upstreamDataSender: streamDataRouter,
                playSyncManager: playSyncManager,
                contextManager: contextManager,
                directiveSequencer: directiveSequencer
            )
        }
        
        addComponent(TextAgentProtocol.self) { resolver -> TextAgentProtocol? in
            let textAgent = TextAgent(
                contextManager: contextManager,
                upstreamDataSender: streamDataRouter,
                focusManager: focusManager,
                channelPriority: .recognition
            )
            
            textAgent.add(delegate: resolver.resolve(DialogStateAggregator.self)!)
            
            return textAgent
        }
        
        addComponent(ExtensionAgentProtocol.self) { _ in
            return ExtensionAgent(
                upstreamDataSender: streamDataRouter,
                contextManager: contextManager,
                directiveSequencer: directiveSequencer
            )
        }
        
        addComponent(LocationAgentProtocol.self) { _ in
            return LocationAgent(contextManager: contextManager)
        }
        
        addComponent(SystemAgentProtocol.self) { _ in
            return SystemAgent(
                contextManager: contextManager,
                networkManager: networkManager,
                upstreamDataSender: streamDataRouter,
                directiveSequencer: directiveSequencer
            )
        }
    }
}

// MARK: - Helper functions

extension NuguClient {
    public func addComponent<Component>(_ componentType: Component.Type, option: ComponentKey.Option = .representative, factory: @escaping (ComponentResolver) -> Component?) {
        let additionalComponent = factory(coreContainer.union(additionalContainer))
        additionalContainer.register(componentType, option: option) { _ in additionalComponent }
    }
    
    public func getComponent<Component>(_ componentType: Component.Type) -> Component? {
        return additionalContainer.resolve(componentType.self)
    }
    
    public func getComponent<Component, Concreate>(_ componentType: Component.Type, concreateType: Concreate.Type, option: ComponentKey.Option = .all) -> Concreate? {
        return additionalContainer.resolve(componentType.self, concreateType: concreateType, option: option)
    }
    
    public func connect() {
        guard let networkManager = coreContainer.resolve(NetworkManageable.self) else {
            return
        }
        
        networkManager.connect()
    }
    
    public func disconnect() {
        guard let networkManager = coreContainer.resolve(NetworkManageable.self) else {
            return
        }
        
        networkManager.disconnect()
    }
    
    public func enable() {
        connect()
    }
    
    public func disable() {
        if let focusManager = coreContainer.resolve(FocusManageable.self) {
            focusManager.stopForegroundActivity()
        }
        
        if let inputProvider = coreContainer.resolve(AudioProvidable.self) {
            inputProvider.stop()
        }
        
        disconnect()
    }
}

// MARK: - Audio Stream Control

extension NuguClient: AudioStreamDelegate {
    private func setupAudioStream() {
        if let audioStream = coreContainer.resolve(AudioStreamable.self) as? AudioStream {
            audioStream.delegate = self
        }
    }

    public func audioStreamWillStart() {
        inputControlWorkItem?.cancel()
        inputControlQueue.async { [weak self] in
            guard let sharedAudioStream = self?.coreContainer.resolve(AudioStreamable.self),
                self?.coreContainer.resolve(AudioProvidable.self)?.isRunning == false else {
                    log.debug("input provider is already started.")
                    return
            }

            self?.delegate?.nuguClientWillOpenInputSource()
            
            do {
                try self?.coreContainer.resolve(AudioProvidable.self)?.start(streamWriter: sharedAudioStream.makeAudioStreamWriter())

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
            
            guard self.coreContainer.resolve(AudioProvidable.self)?.isRunning == true else {
                log.debug("input provider is not running")
                return
            }
            
            self.coreContainer.resolve(AudioProvidable.self)?.stop()
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
