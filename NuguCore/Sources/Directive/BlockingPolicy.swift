//
//  BlockingPolicy.swift
//  NuguCore
//
//  Created by MinChul Lee on 2020/03/20.
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

/// <#Description#>
public struct BlockingPolicy {
    /// <#Description#>
    public let medium: Medium
    /// <#Description#>
    public let isBlocking: Bool
    
    /// <#Description#>
    /// - Parameters:
    ///   - medium: <#medium description#>
    ///   - isBlocking: <#isBlocking description#>
    public init(medium: Medium, isBlocking: Bool) {
        self.medium = medium
        self.isBlocking = isBlocking
    }
    
    /// <#Description#>
    public enum Medium: CaseIterable {
        case none
        case audio
        case visual
        case any
    }
}
