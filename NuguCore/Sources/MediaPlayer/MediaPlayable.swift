//
//  MediaPlayable.swift
//  NuguCore
//
//  Created by MinChul Lee on 22/04/2019.
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

/// <#Description#>
public protocol MediaPlayable: AnyObject {
    /// <#Description#>
    var delegate: MediaPlayerDelegate? { get set }
    
    /// Returns the current time of the current player item.
    var offset: TimeIntervallic { get }
    
    /// The duration of the current player item.
    var duration: TimeIntervallic { get }
    
    /// The audio playback volume for the player.
    var volume: Float { get set }
    
    /// The audio playback speed for the player
    var speed: Float { get set }
    
    /// Begins playback of the current item.
    func play()
    
    /// Stop playback.
    func stop()
    
    /// Pauses playback.
    func pause()
    
    /// Begins playback of the current item.
    func resume()
    
    /// Sets the current playback time to the specified time.
    ///
    /// - Parameter offset: The time(seconds) to which to seek.
    func seek(to offset: TimeIntervallic, completion: ((EndedUp<Error>) -> Void)?)
}

// MARK: - MediaPlayable + Optional

public extension MediaPlayable {
    /// Sets the current playback time to the specified time.
    ///
    /// - Parameter offset: The time(seconds) to which to seek.
    func seek(to offset: TimeIntervallic) {
        seek(to: offset, completion: nil)
    }
}
