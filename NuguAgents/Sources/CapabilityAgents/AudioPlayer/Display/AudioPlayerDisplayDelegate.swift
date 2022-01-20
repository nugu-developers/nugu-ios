//
//  AudioPlayerDisplayDelegate.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2019/07/17.
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

/// The DisplayPlayerAgent delegate is used to notify observers when a player template directive is received.
public protocol AudioPlayerDisplayDelegate: AnyObject {
    /// Tells the delegate that the specified template should be displayed.
    ///
    /// - Parameter template: The player template to display.
    func audioPlayerDisplayShouldRender(template: AudioPlayerDisplayTemplate, completion: @escaping (AnyObject?) -> Void)
    
    /// Tells the delegate that the specified template should be removed from the screen.
    ///
    /// - Parameter template: The template to remove from the screen.
    func audioPlayerDisplayDidClear(template: AudioPlayerDisplayTemplate)
    
    /// Tells the delegate that the specified template should be updated from the screen.
    ///
    /// - Parameter template: The template to update the screen.
    /// - Parameter header: The header of the originally handled directive.
    func audioPlayerDisplayShouldUpdateMetadata(payload: AudioPlayerUpdateMetadataPayload, header: Downstream.Header)
    
    /// Tells the delegate that the displayed template should show lyrics
    /// - Parameter header: The header of the originally handled directive.
    /// - Parameter completion: Whether succeed or not
    func audioPlayerDisplayShouldShowLyrics(completion: @escaping (Bool) -> Void)
    
    /// Tells the delegate that the displayed template should hide lyrics
    /// - Parameter header: The header of the originally handled directive.
    /// - Parameter completion: Whether succeed or not
    func audioPlayerDisplayShouldHideLyrics(completion: @escaping (Bool) -> Void)
    
    /// Tells the delegate that the displayed template should scroll with given direction.
    /// - Parameter direction: Direction to scroll.
    /// - Parameter header: The header of the originally handled directive.
    /// - Parameter completion: Whether succeeded or not
    func audioPlayerDisplayShouldControlLyricsPage(direction: AudioPlayerDisplayControlPayload.Direction, completion: @escaping (Bool) -> Void)
    
    /// <#Description#>
    /// - Parameter completion: <#completion description#>
    func audioPlayerIsLyricsVisible(completion: @escaping (Bool) -> Void)
}
