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

import NuguCore
import NuguUtils

/// The `AudioPlayerAgent` handles directives for controlling audio playback.
public protocol AudioPlayerAgentProtocol: CapabilityAgentable, TypedNotifyable {
    var isPlaying: Bool { get }
    
    /// Sets a delegate to be notified of `AudioPlayerDisplayTemplate` changes.
    var displayDelegate: AudioPlayerDisplayDelegate? { get set }
    
    /// Returns the current time of the current player item.
    ///
    /// This function retrieves the offset(seconds) of the current `MediaPlayable` handled by the `AudioPlayerAgent`.
    var offset: Int? { get }
    
    /// The duration of the current player item.
    ///
    /// This function retrieves the duration(seconds) of the current `MediaPlayable` handled by the `AudioPlayerAgent`.
    var duration: Int? { get }
    
    /// The audio playback volume for the player.
    ///
    /// This function retrieves the volume of the current `MediaPlayable` handled by the `AudioPlayerAgent`.
    var volume: Float { get set }
    
    /// Begins playback of the current item.
    func play()
    
    /// Stop playback.
    func stop()
    
    /// Initiates playback of the next item.
    ///
    /// - Parameter completion: The completion handler to call when the request is complete.
    /// - Returns: The dialogRequestId for request.
    @discardableResult func next(completion: ((StreamDataState) -> Void)?) -> String
    
    /// initiates playback of the previous item.
    ///
    /// - Parameter completion: The completion handler to call when the request is complete.
    /// - Returns: The dialogRequestId for request.
    @discardableResult func prev(completion: ((StreamDataState) -> Void)?) -> String
    
    /// Pauses playback.
    func pause()
    
    /// Change favorite status by sending current status as on / off.
    func requestFavoriteCommand(current: Bool)
    
    /// Change repeatMode by sending current repeatMode as all / one / none.
    func requestRepeatCommand(currentMode: AudioPlayerDisplayRepeat)
    
    /// Change shuffle status by sending current status as on / off.
    func requestShuffleCommand(current: Bool)
    
    /// Sets the current playback time to the specified time.
    ///
    /// - Parameter offset: The time(seconds) to which to seek.
    func seek(to offset: Int)
    
    /// This should be called when occur interaction(input event such as touch, drag, etc...) for display
    func notifyUserInteraction()
}

// MARK: - Default

public extension AudioPlayerAgentProtocol {
    @discardableResult func next() -> String {
        return next(completion: nil)
    }
    
    /// initiates playback of the previous item.
    @discardableResult func prev() -> String {
        return prev(completion: nil)
    }
}
