//
//  NuguTimeInterval.swift
//  NuguUtils
//
//  Created by yonghoonKwon on 2019/11/22.
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

/// Represents a time interval
public struct NuguTimeInterval {
    /// A number of seconds.
    public let seconds: Double
    
    /// Creates a `NuguTimeInterval`
    /// - Parameter seconds: The number of seconds.
    public init(seconds: Double) {
        self.seconds = seconds
    }
    
    /// Creates a `NuguTimeInterval`
    /// - Parameter seconds: The number of seconds.
    public init(seconds: Int) {
        self.seconds = Double(seconds)
    }
    
    /// Creates a `NuguTimeInterval`
    /// - Parameter seconds: The number of milliseconds.
    public init(milliseconds: Double) {
        self.seconds = milliseconds / 1000.0
    }
    
    /// Creates a `NuguTimeInterval`
    /// - Parameter seconds: The number of milliseconds.
    public init(milliseconds: Int) {
        self.seconds = Double(milliseconds) / 1000.0
    }
}
