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
    
    public func makeASRAgent(container: NuguClientContainer) -> ASRAgentProtocol? {
        return ASRAgent(
            focusManager: container.focusManager,
            channelPriority: .recognition,
            upstreamDataSender: container.streamDataRouter,
            contextManager: container.contextManager,
            audioStream: container.sharedAudioStream,
            endPointDetector: container.endPointDetector,
            dialogStateAggregator: container.dialogStateAggregator,
            directiveSequencer: container.directiveSequencer
        )
    }
    
    public func makeTTSAgent(container: NuguClientContainer) -> TTSAgentProtocol? {
        return TTSAgent(
            focusManager: container.focusManager,
            channelPriority: .information,
            mediaPlayerFactory: container.mediaPlayerFactory,
            upstreamDataSender: container.streamDataRouter,
            playSyncManager: container.playSyncManager,
            contextManager: container.contextManager,
            directiveSequencer: container.directiveSequencer
        )
    }
    
    public func makeAudioPlayerAgent(container: NuguClientContainer) -> AudioPlayerAgentProtocol? {
        return AudioPlayerAgent(
            focusManager: container.focusManager,
            channelPriority: .content,
            mediaPlayerFactory: container.mediaPlayerFactory,
            upstreamDataSender: container.streamDataRouter,
            playSyncManager: container.playSyncManager,
            contextManager: container.contextManager,
            directiveSequencer: container.directiveSequencer
        )
    }
    
    public func makeTextAgent(container: NuguClientContainer) -> TextAgentProtocol? {
        return TextAgent(
            contextManager: container.contextManager,
            upstreamDataSender: container.streamDataRouter,
            focusManager: container.focusManager,
            channelPriority: .recognition,
            dialogStateAggregator: container.dialogStateAggregator
        )
    }
    
    public func makeExtensionAgent(container: NuguClientContainer) -> ExtensionAgentProtocol? {
        return ExtensionAgent(
            upstreamDataSender: container.streamDataRouter,
            contextManager: container.contextManager,
            directiveSequencer: container.directiveSequencer
        )
    }
    
    public func makeLocationAgent(container: NuguClientContainer) -> LocationAgentProtocol? {
        return LocationAgent(contextManager: container.contextManager)
    }
    
    public func makeDisplayAgent(container: NuguClientContainer) -> DisplayAgentProtocol? {
        return DisplayAgent(
            upstreamDataSender: container.streamDataRouter,
            playSyncManager: container.playSyncManager,
            contextManager: container.contextManager,
            directiveSequencer: container.directiveSequencer
        )
    }
}
