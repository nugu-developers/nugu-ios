//
//  DirectiveCancelPolicy.swift
//  NuguCore
//
//  Created by MinChul Lee on 2020/08/13.
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
public struct DirectiveCancelPolicy {
    /// <#Description#>
    public let cancelAll: Bool
    /// <#Description#>
    public let cancelTargets: [String]
    
    /// <#Description#>
    /// - Parameters:
    ///   - cancelAll: <#cancelAll description#>
    ///   - cancelTargets: <#cancelTargets description#>
    public init(cancelAll: Bool, cancelTargets: [String]) {
        self.cancelAll = cancelAll
        self.cancelTargets = cancelTargets
    }
    
    /// <#Description#>
    public static let cancelAll = DirectiveCancelPolicy(cancelAll: true, cancelTargets: [])
    /// <#Description#>
    public static let cancelNone = DirectiveCancelPolicy(cancelAll: false, cancelTargets: [])
}
