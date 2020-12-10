//
//  AudioPlayerAgentDelegate.swift
//  NuguAgents
//
//  Created by MinChul Lee on 25/04/2019.
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

/// An delegate that appllication can extend to register to observe `AudioPlayerState` changes.
public protocol AudioPlayerAgentDelegate: class {
    ///  Used to notify the observer of state changes.
    /// - Parameter state: The new AudioPlayerState of the `AudioPlayerAgent`
    /// - Parameter header: The header of the originally handled directive.
    func audioPlayerAgentDidChange(state: AudioPlayerState, header: Downstream.Header)
    
    ///  Used to notify the observer of duration changes.
    /// - Parameter duration: The duration of the current player item.
    func audioPlayerAgentDidChange(duration: Int)
}
