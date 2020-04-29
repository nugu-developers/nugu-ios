//
//  MediaUrlDataSource.swift
//  NuguCore
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
    func setSource(url: String, offset: TimeIntervallic, cacheKey: String?)
    
    /// For url source
    func setSource(url: URL, offset: TimeIntervallic, cacheKey: String?)
}

// MARK: - MediaUrlDataSource

public extension MediaUrlDataSource {
    /// For url source
    func setSource(url: String) {
        setSource(url: url, offset: NuguTimeInterval(seconds: 0), cacheKey: nil)
    }
    
    /// For url source
    func setSource(url: URL) {
        setSource(url: url, offset: NuguTimeInterval(seconds: 0), cacheKey: nil)
    }
}
