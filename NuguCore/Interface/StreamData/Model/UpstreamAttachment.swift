//
//  UpstreamAttachment.swift
//  NuguCore
//
//  Created by MinChul Lee on 22/05/2019.
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
public struct UpstreamAttachment {
    /// <#Description#>
    public let header: UpstreamHeader
    /// <#Description#>
    public let content: Data
    /// <#Description#>
    public let seq: Int32
    /// <#Description#>
    public let isEnd: Bool
    /// <#Description#>
    public let type: String
    
    /// <#Description#>
    /// - Parameter header: <#header description#>
    /// - Parameter content: <#content description#>
    /// - Parameter seq: <#seq description#>
    /// - Parameter isEnd: <#isEnd description#>
    public init(header: UpstreamHeader, content: Data, type: String, seq: Int32, isEnd: Bool) {
        self.header = header
        self.content = content
        self.type = type
        self.seq = seq
        self.isEnd = isEnd
    }
}
