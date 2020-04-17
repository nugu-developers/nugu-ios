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

/// The DisplayPlayerAgent delegate is used to notify observers when a player template directive is received.
public protocol AudioPlayerDisplayDelegate: class {
    /// Tells the delegate that the specified template should be displayed.
    ///
    /// - Parameter template: The player template to display.
    func audioPlayerDisplayDidRender(template: AudioPlayerDisplayTemplate) -> AnyObject?
    
    /// Tells the delegate that the specified template should be removed from the screen.
    ///
    /// - Parameter template: The template to remove from the screen.
    /// - Parameter reason: Reason to clear the template.
    func audioPlayerDisplayShouldClear(template: AudioPlayerDisplayTemplate)
    
    /// Tells the delegate that the specified template should be updated from the screen.
    ///
    /// - Parameter template: The template to update the screen.
    func audioPlayerDisplayShouldUpdateMetadata(payload: Data)
    
    func audioPlayerDisplayShouldShowLyrics() -> Bool
    
    func audioPlayerDisplayShouldHideLyrics() -> Bool
    
    func audioPlayerDisplayShouldControlLyricsPage(direction: AudioPlayerDisplayControlPayload.Direction) -> Bool
}
