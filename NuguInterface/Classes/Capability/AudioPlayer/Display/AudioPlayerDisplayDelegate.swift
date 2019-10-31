//
//  AudioPlayerDisplayDelegate.swift
//  NuguInterface
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
    /// Determines whether the player template should be displayed to user.
    /// - Parameter template: The player template to display.
    /// - Returns: Application 의 시나리오에 따라 디스플레이를 원하지 않는 경우 false 를 반환해야 합니다.
    func audioPlayerDisplayShouldRender(template: AudioPlayerDisplayTemplate) -> Bool
    
    /// Tells the delegate that the specified player template should be displayed.
    /// - Parameter template: The player template to display.
    func audioPlayerDisplayDidRender(template: AudioPlayerDisplayTemplate)
    
    /// Determines whether the player template should be remove from the screen.
    /// - Parameter template: The player template to remove from the screen.
    /// - Returns: Application 의 시나리오에 따라 player 을 지속적으로 노출해야 하는 경우 false 를 반환해야 합니다.
    func audioPlayerDisplayShouldClear(template: AudioPlayerDisplayTemplate) -> Bool
    
    /// Tells the delegate that the specified player template should be removed from the screen.
    /// - Parameter template: The player template to remove from the screen.
    func audioPlayerDisplayDidClear(template: AudioPlayerDisplayTemplate)
}
