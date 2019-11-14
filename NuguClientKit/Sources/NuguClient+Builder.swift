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
        public lazy var wakeUpDetector = KeyWordDetector()
        
        // MARK: - Capability Agents
        
        /// <#Description#>
        public lazy var asrAgent: ASRAgentProtocol? = ASRAgent()
        /// <#Description#>
        public lazy var ttsAgent: TTSAgentProtocol? = TTSAgent()
        /// <#Description#>
        public lazy var audioPlayerAgent: AudioPlayerAgentProtocol? = AudioPlayerAgent()
        /// <#Description#>
        public lazy var displayAgent: DisplayAgentProtocol? = DisplayAgent()
        /// <#Description#>
        public lazy var textAgent: TextAgentProtocol? = TextAgent()
        /// <#Description#>
        public lazy var extensionAgent: ExtensionAgentProtocol? = ExtensionAgent()
        /// <#Description#>
        public lazy var locationAgent: LocationAgentProtocol? = LocationAgent()
        /// <#Description#>
        public lazy var permissionAgent: PermissionAgentProtocol? = PermissionAgentProtocol()
        
        /// <#Description#>
        public init() {}
        
        /// <#Description#>
        public func build() -> NuguClient {
            return NuguClient(
                inputProvider: inputProvider,
                sharedAudioStream: sharedAudioStream,
                endPointDetector: endPointDetector,
                wakeUpDetector: wakeUpDetector,
                asrAgent: asrAgent,
                ttsAgent: ttsAgent,
                audioPlayerAgent: audioPlayerAgent,
                displayAgent: displayAgent,
                textAgent: textAgent,
                extensionAgent: extensionAgent,
                locationAgent: locationAgent,
                permissionAgent: permissionAgent
            )
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
    public func with(wakeUpDetector: KeyWordDetector) -> Self {
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
    
    /// <#Description#>
    /// - Parameter permissionAgent: <#extensionAgent description#>
    public func with(permissionAgent: PermissionAgentProtocol?) -> Self {
        self.permissionAgent = permissionAgent
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
