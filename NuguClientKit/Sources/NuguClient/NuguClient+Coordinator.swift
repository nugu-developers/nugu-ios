//
//  NuguClient+Coordinator.swift
//  NuguClientKit
//
//  Created by DCs-OfficeMBP on 20/06/2019.
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

import NuguInterface
import NuguCore

// MARK: - Coordinator

extension NuguClient {
    func setupDependencies() {
        // Setup managers
        networkManager.add(receiveMessageDelegate: downStreamDataInterpreter)
        downStreamDataInterpreter.add(delegate: directiveSequencer)
        contextManager.add(provideContextDelegate: playSyncManager)
        dialogStateAggregator.add(delegate: focusManager)
        
        // Setup capability-agents
        setupASRAgentDependency()
        setupTTSAgentDependency()
        setupAudioPlayerAgentDependency()
        setupDisplayAgentDependency()
        setupSystemAgentDependency()
        setupTextAgentDependency()
        setupExtensionAgentDependency()
        setupLocationAgentDependency()
        
        // Setup core
        setupAudioStreamDependency()
        setupWakeUpDetectorDependency()
    }
}

// MARK: - Capability-Agents (Optional)

extension NuguClient {
    func setupASRAgentDependency() {
        guard let agent = asrAgent else { return }
        
        agent.focusManager = focusManager
        agent.channel = FocusChannelConfiguration.recognition
        agent.messageSender = networkManager
        agent.contextManager = contextManager
        agent.audioStream = sharedAudioStream
        agent.dialogStateAggregator = dialogStateAggregator
        agent.endPointDetector = endPointDetector
        
        directiveSequencer.add(handleDirectiveDelegate: agent)
        contextManager.add(provideContextDelegate: agent)
        focusManager.add(channelDelegate: agent)
        downStreamDataInterpreter.add(delegate: agent)
        agent.add(delegate: dialogStateAggregator)
    }
    
    func setupTTSAgentDependency() {
        guard let agent = ttsAgent else { return }
        
        agent.focusManager = focusManager
        agent.channel = FocusChannelConfiguration.information
        agent.mediaPlayerFactory = mediaPlayerFactory
        agent.messageSender = networkManager
        agent.playSyncManager = playSyncManager
        
        directiveSequencer.add(handleDirectiveDelegate: agent)
        agent.add(delegate: dialogStateAggregator)
        contextManager.add(provideContextDelegate: agent)
        focusManager.add(channelDelegate: agent)
    }
    
    func setupAudioPlayerAgentDependency() {
        guard let agent = audioPlayerAgent else { return }
        
        agent.focusManager = focusManager
        agent.channel = FocusChannelConfiguration.content
        agent.mediaPlayerFactory = mediaPlayerFactory
        agent.messageSender = networkManager
        agent.playSyncManager = playSyncManager

        directiveSequencer.add(handleDirectiveDelegate: agent)
        contextManager.add(provideContextDelegate: agent)
        focusManager.add(channelDelegate: agent)
    }
    
    func setupDisplayAgentDependency() {
        guard let agent = displayAgent else { return }
        
        agent.messageSender = networkManager
        agent.playSyncManager = playSyncManager
        
        directiveSequencer.add(handleDirectiveDelegate: agent)
        contextManager.add(provideContextDelegate: agent)
    }
    
    func setupTextAgentDependency() {
        guard let agent = textAgent else { return }
        
        agent.channel = FocusChannelConfiguration.recognition
        agent.contextManager = contextManager
        agent.messageSender = networkManager
        agent.focusManager = focusManager
        agent.dialogStateAggregator = dialogStateAggregator
        
        contextManager.add(provideContextDelegate: agent)
        downStreamDataInterpreter.add(delegate: agent)
        focusManager.add(channelDelegate: agent)
        agent.add(delegate: dialogStateAggregator)
    }
    
    func setupExtensionAgentDependency() {
        guard let agent = extensionAgent else { return }
        
        agent.messageSender = networkManager
        
        directiveSequencer.add(handleDirectiveDelegate: agent)
        contextManager.add(provideContextDelegate: agent)
    }
    
    func setupLocationAgentDependency() {
        guard let agent = locationAgent else { return }
        
        contextManager.add(provideContextDelegate: agent)
    }
}

// MARK: - Capability-Agents (Mandatory)

extension NuguClient {
    func setupSystemAgentDependency() {
        systemAgent.contextManager = contextManager
        systemAgent.networkManager = networkManager
        
        directiveSequencer.add(handleDirectiveDelegate: systemAgent)
        contextManager.add(provideContextDelegate: systemAgent)
        networkManager.add(statusDelegate: systemAgent)
        dialogStateAggregator.add(delegate: systemAgent)
    }
}

// MARK: - Core

extension NuguClient {
    func setupAudioStreamDependency() {
        guard let audioStream = sharedAudioStream as? AudioStream else { return }
        
        audioStream.delegate = self
    }
    
    func setupWakeUpDetectorDependency() {
        guard let wakeUpDetector = wakeUpDetector else { return }
        
        wakeUpDetector.audioStream = sharedAudioStream
        
        contextManager.add(provideContextDelegate: wakeUpDetector)
    }
}
