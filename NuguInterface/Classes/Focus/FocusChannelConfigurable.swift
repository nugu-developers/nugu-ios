//
//  FocusChannelConfigurable.swift
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

/// The configuration used by the FocusManager to create Channel objects. Each configuration object has a name and priority.
public protocol FocusChannelConfigurable {
    /// The name of the channel.
    var name: String { get }
    /// The priority of the channel.
    var priority: Int { get }
}
