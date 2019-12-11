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
        return BuiltInASRAgent(
            focusManager: container.focusManager,
            channel: FocusChannelConfiguration.recognition,
            messageSender: container.networkManager,
            contextManager: container.contextManager,
            audioStream: container.sharedAudioStream,
            endPointDetector: container.endPointDetector,
            dialogStateAggregator: container.dialogStateAggregator
        )
    }
    
    public func makeTTSAgent(container: NuguClientContainer) -> TTSAgentProtocol? {
        return BuiltInTTSAgent(
            focusManager: container.focusManager,
            channel: FocusChannelConfiguration.information,
            mediaPlayerFactory: container.mediaPlayerFactory,
            messageSender: container.networkManager,
            playSyncManager: container.playSyncManager
        )
    }
    
    public func makeAudioPlayerAgent(container: NuguClientContainer) -> AudioPlayerAgentProtocol? {
        return BuiltInAudioPlayerAgent(
            focusManager: container.focusManager,
            channel: FocusChannelConfiguration.content,
            mediaPlayerFactory: container.mediaPlayerFactory,
            messageSender: container.networkManager,
            playSyncManager: container.playSyncManager
        )
    }
    
    public func makeTextAgent(container: NuguClientContainer) -> TextAgentProtocol? {
        return BuiltInTextAgent(
            contextManager: container.contextManager,
            messageSender: container.networkManager,
            focusManager: container.focusManager,
            channel: FocusChannelConfiguration.recognition,
            dialogStateAggregator: container.dialogStateAggregator
        )
    }
    
    public func makeExtensionAgent(container: NuguClientContainer) -> ExtensionAgentProtocol? {
        return BuiltInExtensionAgent(messageSender: container.networkManager)
    }
    
    public func makeLocationAgent(container: NuguClientContainer) -> LocationAgentProtocol? {
        return BuiltInLocationAgent()
    }
    
    public func makeDisplayAgent(container: NuguClientContainer) -> DisplayAgentProtocol? {
        return BuiltInDisplayAgent(
            messageSender: container.networkManager,
            playSyncManager: container.playSyncManager
        )
    }
}
