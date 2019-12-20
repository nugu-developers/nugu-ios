//
//  BuiltInCapabilityAgentFactory.swift
//  NuguClientKit
//
//  Created by yonghoonKwon on 2019/12/11.
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

public class BuiltInCapabilityAgentFactory: CapabilityAgentFactory {
    public init() {}
    
    public func makeASRAgent(container: NuguClientContainer) -> (ASRAgentProtocol & CapabilityAgentable)? {
        return ASRAgent(
            focusManager: container.focusManager,
            channelPriority: .recognition,
            upstreamDataSender: container.streamDataRouter,
            contextManager: container.contextManager,
            audioStream: container.sharedAudioStream,
            endPointDetector: container.endPointDetector,
            dialogStateAggregator: container.dialogStateAggregator
        )
    }
    
    public func makeTTSAgent(container: NuguClientContainer) -> (TTSAgentProtocol & CapabilityAgentable)? {
        return TTSAgent(
            focusManager: container.focusManager,
            channelPriority: .information,
            mediaPlayerFactory: container.mediaPlayerFactory,
            upstreamDataSender: container.streamDataRouter,
            playSyncManager: container.playSyncManager
        )
    }
    
    public func makeAudioPlayerAgent(container: NuguClientContainer) -> (AudioPlayerAgentProtocol & CapabilityAgentable)? {
        return AudioPlayerAgent(
            focusManager: container.focusManager,
            channelPriority: .content,
            mediaPlayerFactory: container.mediaPlayerFactory,
            upstreamDataSender: container.streamDataRouter,
            playSyncManager: container.playSyncManager
        )
    }
    
    public func makeTextAgent(container: NuguClientContainer) -> (TextAgentProtocol & CapabilityAgentable)? {
        return TextAgent(
            contextManager: container.contextManager,
            upstreamDataSender: container.streamDataRouter,
            focusManager: container.focusManager,
            channelPriority: .recognition,
            dialogStateAggregator: container.dialogStateAggregator
        )
    }
    
    public func makeExtensionAgent(container: NuguClientContainer) -> (ExtensionAgentProtocol & CapabilityAgentable)? {
        return ExtensionAgent(upstreamDataSender: container.streamDataRouter)
    }
    
    public func makeLocationAgent(container: NuguClientContainer) -> (LocationAgentProtocol & CapabilityAgentable)? {
        return LocationAgent()
    }
    
    public func makeDisplayAgent(container: NuguClientContainer) -> (DisplayAgentProtocol & CapabilityAgentable)? {
        return DisplayAgent(
            upstreamDataSender: container.streamDataRouter,
            playSyncManager: container.playSyncManager
        )
    }
}
