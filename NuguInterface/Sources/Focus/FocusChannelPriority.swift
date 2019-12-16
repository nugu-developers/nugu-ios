//
//  FocusChannelPriority.swift
//  NuguInterface
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
public struct FocusChannelPriority: RawRepresentable {
    public typealias RawValue = Int
    
    /// The `rawValue` is priority of the channel
    public var rawValue: Int
    
    /// A priority of `recognition` channel is 300
    public static let recognition = FocusChannelPriority(rawValue: 300)
    /// A priority of `information` channel is 200
    public static let information = FocusChannelPriority(rawValue: 200)
    /// A priority of `content` channel is 100
    public static let content = FocusChannelPriority(rawValue: 100)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
