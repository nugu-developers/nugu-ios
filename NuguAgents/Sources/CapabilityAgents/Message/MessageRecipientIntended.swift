//
//  MessageRecipientIntended.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/01/11.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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
public struct MessageRecipientIntended: Codable {
    /// <#Description#>
    public let name: String?
    /// <#Description#>
    public let label: String?
    
    /// The initializer for `MessageRecipientIntended`.
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - label: <#label description#>
    public init(name: String?, label: String?) {
        self.name = name
        self.label = label
    }
}
