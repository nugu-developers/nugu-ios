//
//  MediaUrlDataSource.swift
//  NuguInterface
//
//  Created by yonghoonKwon on 2019/11/27.
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

public protocol MediaUrlDataSource {
    /// For url source
    /// - Parameter url: <#url description#>
    /// - Parameter offset: <#offset description#>
    func setSource(url: String, offset: TimeIntervallic) throws
}

// MARK: - MediaUrlDataSource

public extension MediaUrlDataSource {
    /// <#Description#>
    /// - Parameter url: <#url description#>
    func setSource(url: String) throws {
        try setSource(url: url, offset: NuguTimeInterval(seconds: 0))
    }
}
