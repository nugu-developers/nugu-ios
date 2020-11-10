//
//  FocusState.swift
//  NuguCore
//
//  Created by MinChul Lee on 24/04/2019.
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

/// An enum class used to specify the levels of focus that a Channel can have.
public enum FocusState {
    /// Indicate the channel will request focus..
    case prepare
    /// Represents the highest focus a Channel can have.
    case foreground
    /// Represents the intermediate level focus a Channel can have.
    case background
    /// This focus is used to represent when a Channel is not being used or when an observer should stop.
    case nothing
}
