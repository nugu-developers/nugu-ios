//
//  AudioPlayerAgentProtocol.swift
//  NuguAgents
//
//  Created by MinChul Lee on 05/05/2019.
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

/// The `AudioPlayerAgent` handles directives for controlling audio playback.
public protocol AudioPlayerAgentProtocol: CapabilityAgentable {
    /// Adds a delegate to be notified of `AudioPlayerState` changes.
    /// - Parameter delegate: The object to add.
    func add(delegate: AudioPlayerAgentDelegate)
    
    /// Removes a delegate from AudioPlayerAgent.
    /// - Parameter delegate: The object to remove.
    func remove(delegate: AudioPlayerAgentDelegate)
    
    /// This function retrieves the offset(seconds) of the current `MediaPlayable` the `AudioPlayerAgent` is handling.
    var offset: Int? { get }
    
    /// This function retrieves the duration(seconds) of the current `MediaPlayable` the `AudioPlayerAgent` is handling.
    var duration: Int? { get }
    
    /// Begins playback of the current item.
    func play()
    
    /// Stop playback.
    func stop()
    
    /// Initiates playback of the next item.
    func next()
    
    /// initiates playback of the previous item.
    func prev()
    
    /// Pauses playback.
    func pause()
    
    /// Set favorite as on / off.
    func favorite(isOn: Bool)
    
    /// Set repeatMode as all / one / none.
    func repeatMode(repeatMode: String)
    
    /// Set shuffle as on / off.
    func shuffle(isOn: Bool)
    
    /// Sets the current playback time to the specified time.
    ///
    /// - Parameter offset: The time(seconds) to which to seek.
    func seek(to offset: Int)
    
    /// Adds a delegate to be notified of `AudioPlayerDisplayTemplate` changes.
    ///
    /// - Parameter displayDelegate: The object to add.
    func add(displayDelegate: AudioPlayerDisplayDelegate)
    
    /// Removes a delegate from AudioPlayerAgent.
    ///
    /// - Parameter displayDelegate: The object to remove.
    func remove(displayDelegate: AudioPlayerDisplayDelegate)
    
    /// Stops the timer for deleting template by timeout.
    ///
    /// - Parameter templateId: The unique identifier for the template.
    func stopRenderingTimer(templateId: String)
}
