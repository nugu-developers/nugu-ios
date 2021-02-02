//
//  SoundAgentProtocol.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/04/07.
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

import NuguUtils

/// `SoundAgent` is needed to play beep sound.
public protocol SoundAgentProtocol: CapabilityAgentable, TypedNotifyable {
    /// The data source for the beep.
    var dataSource: SoundAgentDataSource? { get set }
    
    /// The beep playback volume for the player.
    ///
    /// This function retrieves the volume of the current `MediaPlayable` handled by the sound-agent.
    var volume: Float { get set }
}
