//
//  NuguClient+Builder.swift
//  NuguClientKit
//
//  Created by yonghoonKwon on 27/06/2019.
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
import JadeMarble

extension NuguClient {
    /// <#Description#>
    public class Builder {
        public lazy var inputProvider: AudioProvidable = MicInputProvider()
        public lazy var sharedAudioStream: AudioStreamable = AudioStream(capacity: 300)
        public lazy var endPointDetector: EndPointDetectable = EndPointDetector()
        public lazy var wakeUpDetector = KeywordDetector()
        
        /// <#Description#>
        public let authorizationManager = AuthorizationManager.shared
        /// <#Description#>
        public let focusManager: FocusManageable = FocusManager()
        /// <#Description#>
        public let networkManager: NetworkManageable = NetworkManager()
        /// <#Description#>
        public let dialogStateAggregator: DialogStateAggregatable = DialogStateAggregator()
        /// <#Description#>
        public let contextManager: ContextManageable = ContextManager()
        /// <#Description#>
        public let playSyncManager: PlaySyncManageable = PlaySyncManager()
        /// <#Description#>
        public let downStreamDataInterpreter: DownStreamDataInterpretable = DownStreamDataInterpreter()
        /// <#Description#>
        let mediaPlayerFactory = MediaPlayerFactory()
        
        public lazy var directiveSequencer: DirectiveSequenceable = DirectiveSequencer(messageSender: networkManager)
        
        // MARK: - Capability Agents
        
        /// <#Description#>
        public lazy var systemAgent: SystemAgentProtocol = SystemAgent(
            contextManager: contextManager,
            networkManager: networkManager
        )
        
        /// <#Description#>
        public lazy var asrAgent: ASRAgentProtocol? = ASRAgent(
            focusManager: focusManager,
            channel: FocusChannelConfiguration.recognition,
            messageSender: networkManager,
            contextManager: contextManager,
            audioStream: sharedAudioStream,
            endPointDetector: endPointDetector,
            dialogStateAggregator: dialogStateAggregator
        )
        
        /// <#Description#>
        public lazy var ttsAgent: TTSAgentProtocol? = TTSAgent(
            focusManager: focusManager,
            channel: FocusChannelConfiguration.information,
            mediaPlayerFactory: mediaPlayerFactory,
            messageSender: networkManager,
            playSyncManager: playSyncManager
        )
        
        /// <#Description#>
        public lazy var audioPlayerAgent: AudioPlayerAgentProtocol? = AudioPlayerAgent(
            focusManager: focusManager,
            channel: FocusChannelConfiguration.content,
            mediaPlayerFactory: mediaPlayerFactory,
            messageSender: networkManager,
            playSyncManager: playSyncManager
        )
        
        /// <#Description#>
        public lazy var displayAgent: DisplayAgentProtocol? = DisplayAgent(
            messageSender: networkManager,
            playSyncManager: playSyncManager
        )
        
        /// <#Description#>
        public lazy var textAgent: TextAgentProtocol? = TextAgent(
            contextManager: contextManager,
            messageSender: networkManager,
            focusManager: focusManager,
            channel: FocusChannelConfiguration.recognition,
            dialogStateAggregator: dialogStateAggregator
        )
        
        /// <#Description#>
        public lazy var extensionAgent: ExtensionAgentProtocol? = ExtensionAgent(
            messageSender: networkManager
        )
        
        /// <#Description#>
        public lazy var locationAgent: LocationAgentProtocol? = LocationAgent()
        
        /// <#Description#>
        public init() {}
        
        /// <#Description#>
        public func build() -> NuguClient {
            let client = NuguClient(
                authorizationManager: authorizationManager,
                focusManager: focusManager,
                networkManager: networkManager,
                dialogStateAggregator: dialogStateAggregator,
                contextManager: contextManager,
                playSyncManager: playSyncManager,
                directiveSequencer: directiveSequencer,
                downStreamDataInterpreter: downStreamDataInterpreter,
                mediaPlayerFactory: mediaPlayerFactory,
                inputProvider: inputProvider,
                sharedAudioStream: sharedAudioStream,
                endPointDetector: endPointDetector,
                wakeUpDetector: wakeUpDetector,
                systemAgent: systemAgent,
                asrAgent: asrAgent,
                ttsAgent: ttsAgent,
                audioPlayerAgent: audioPlayerAgent,
                displayAgent: displayAgent,
                textAgent: textAgent,
                extensionAgent: extensionAgent,
                locationAgent: locationAgent
            )
            
            return client
        }
    }
}

// MARK: - Chaining for builder

extension NuguClient.Builder {
    // MARK: - Base
    
    /// <#Description#>
    /// - Parameter inputProvider: <#inputProvider description#>
    public func with(inputProvider: AudioProvidable) -> Self {
        self.inputProvider = inputProvider
        return self
    }
    
    /// <#Description#>
    /// - Parameter sharedAudioStream: <#sharedAudioStream description#>
    public func with(sharedAudioStream: AudioStreamable) -> Self {
        self.sharedAudioStream = sharedAudioStream
        return self
    }
    
    /// <#Description#>
    /// - Parameter endPointDetector: <#endPointDetector description#>
    public func with(endPointDetector: EndPointDetectable) -> Self {
        self.endPointDetector = endPointDetector
        return self
    }
    
    /// <#Description#>
    /// - Parameter wakeUpDetector: <#wakeUpDetector description#>
    public func with(wakeUpDetector: KeywordDetector) -> Self {
        self.wakeUpDetector = wakeUpDetector
        return self
    }
    
    // MARK: - Capability Agents
    
    /// <#Description#>
    /// - Parameter asrAgent: <#asrAgent description#>
    public func with(asrAgent: ASRAgentProtocol?) -> Self {
        self.asrAgent = asrAgent
        return self
    }
    
    /// <#Description#>
    /// - Parameter ttsAgent: <#ttsAgent description#>
    public func with(ttsAgent: TTSAgentProtocol?) -> Self {
        self.ttsAgent = ttsAgent
        return self
    }
    
    /// <#Description#>
    /// - Parameter audioPlayerAgent: <#audioPlayerAgent description#>
    public func with(audioPlayerAgent: AudioPlayerAgentProtocol?) -> Self {
        self.audioPlayerAgent = audioPlayerAgent
        return self
    }
    
    /// <#Description#>
    /// - Parameter displayAgent: <#displayAgent description#>
    public func with(displayAgent: DisplayAgentProtocol?) -> Self {
        self.displayAgent = displayAgent
        return self
    }

    /// <#Description#>
    /// - Parameter textAgent: <#textAgent description#>
    public func with(textAgent: TextAgentProtocol?) -> Self {
        self.textAgent = textAgent
        return self
    }
    
    /// <#Description#>
    /// - Parameter extensionAgent: <#extensionAgent description#>
    public func with(extensionAgent: ExtensionAgentProtocol?) -> Self {
        self.extensionAgent = extensionAgent
        return self
    }
    
    /// <#Description#>
    /// - Parameter extensionAgent: <#extensionAgent description#>
    public func with(locationAgent: LocationAgentProtocol?) -> Self {
        self.locationAgent = locationAgent
        return self
    }
}

// MARK: - Closure for builder

extension NuguClient.Builder {
    /// <#Description#>
    /// - Parameter closure: <#closure description#>
    public func with(_ closure: ((NuguClient.Builder) -> Void)) -> Self {
        closure(self)
        return self
    }
}
