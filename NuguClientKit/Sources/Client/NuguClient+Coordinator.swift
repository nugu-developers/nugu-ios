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
        networkManager.add(receiveMessageDelegate: streamDataRouter)
        streamDataRouter.add(delegate: directiveSequencer)
        streamDataRouter.add(preprocessor: downstreamDataTimeoutPreprocessor)
        contextManager.add(provideContextDelegate: playSyncManager)
        dialogStateAggregator.add(delegate: focusManager)
        
        // Setup capability-agents
        let capabilityAgents: [CapabilityAgentable?] = [
            asrAgent,
            ttsAgent,
            audioPlayerAgent,
            displayAgent,
            textAgent,
            extensionAgent,
            locationAgent
        ]
        
        capabilityAgents
            .compactMap({ $0 })
            .forEach({ setupCapabilityAgentDependency($0) })
        
        setupDialogStateAggregatorDependency()
        setupDownstreamDataTimeoutPreprocessorDependency()
        setupAuthorizationManagerDependency()
        
        setupAudioStreamDependency()
        setupWakeUpDetectorDependency()
    }
}

// MARK: - Capability-Agents (Optional)

extension NuguClient {
    func setupCapabilityAgentDependency(_ agent: CapabilityAgentable) {
        // ContextInfoDelegate
        contextManager.add(provideContextDelegate: agent)
        
        // HandleDirectiveDelegate
        if let agent = agent as? HandleDirectiveDelegate {
            directiveSequencer.add(handleDirectiveDelegate: agent)
        }
        
        // FocusChannelDelegate
        if let agent = agent as? FocusChannelDelegate {
            focusManager.add(channelDelegate: agent)
        }
        
        // DownstreamDataDelegate
        if let agent = agent as? DownstreamDataDelegate {
            streamDataRouter.add(delegate: agent)
        }
        
        // NetworkStatusDelegate
        if let agent = agent as? NetworkStatusDelegate {
            networkManager.add(statusDelegate: agent)
        }
        
        // DialogStateDelegate
        if let agent = agent as? DialogStateDelegate {
            dialogStateAggregator.add(delegate: agent)
        }
    }
}

// MARK: - Core

extension NuguClient {
    func setupDialogStateAggregatorDependency() {
        asrAgent?.add(delegate: dialogStateAggregator)
        ttsAgent?.add(delegate: dialogStateAggregator)
        textAgent?.add(delegate: dialogStateAggregator)
    }
    
    func setupDownstreamDataTimeoutPreprocessorDependency() {
        asrAgent?.add(delegate: downstreamDataTimeoutPreprocessor)
        textAgent?.add(delegate: downstreamDataTimeoutPreprocessor)
    }
    
    func setupAuthorizationManagerDependency() {
        systemAgent.add(systemAgentDelegate: authorizationManager)
    }
    
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
