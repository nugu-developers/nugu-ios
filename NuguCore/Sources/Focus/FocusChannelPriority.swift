//
//  FocusChannelPriority.swift
//  NuguCore
//
//  Created by MinChul Lee on 11/04/2019.
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

/// The priority of the channel used by the `FocusManager` to create `Channel` objects.
///
/// Use a initializer if you want to create priorities directly in application.
/// The predetermined focus channel includes `recognition`(priority = 300), `information`(priority = 200) and `content`(priority = 100).
public struct FocusChannelPriority {
    public let requestPriority: Int
    public let maintainPriority: Int
    
    /// <#Description#>
    /// - Parameters:
    ///   - requestPriority: <#requestPriority description#>
    ///   - maintainPriority: <#maintainPriority description#>
    public init(requestPriority: Int, maintainPriority: Int) {
        self.requestPriority = requestPriority
        self.maintainPriority = maintainPriority
    }
    
    /// A priority of `call` channel.
    public static let call = FocusChannelPriority(requestPriority: 300, maintainPriority: 300)
    /// A priority of `userRecognition` channel.
    public static let userRecognition = FocusChannelPriority(requestPriority: 300, maintainPriority: 250)
    /// A priority of `dmRecognition` channel.
    public static let dmRecognition = FocusChannelPriority(requestPriority: 150, maintainPriority: 200)
    /// A priority of `alerts` channel.
    public static let alerts = FocusChannelPriority(requestPriority: 250, maintainPriority: 200)
    /// A priority of `information` channel.
    public static let information = FocusChannelPriority(requestPriority: 250, maintainPriority: 200)
    /// A priority of `media` channel.
    public static let media = FocusChannelPriority(requestPriority: 200, maintainPriority: 100)
    /// A priority of `beep` channel.
    public static let beep = FocusChannelPriority(requestPriority: 100, maintainPriority: 150)
    /// A priority of `sound` channel.
    public static let sound = FocusChannelPriority(requestPriority: 100, maintainPriority: 100)
    /// A priority of `background` channel.
    public static let background = FocusChannelPriority(requestPriority: 0, maintainPriority: 100)
}
