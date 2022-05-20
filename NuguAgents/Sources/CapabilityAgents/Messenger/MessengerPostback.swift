//
//  MessengerPostback.swift
//  NuguMessengerAgent
//
//  Created by yonghoonKwon on 2021/06/01.
//  Copyright (c) 2021 SK Telecom Co., Ltd. All rights reserved.
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

public struct MessengerPostback {
    /// <#Description#>
    public let alt: String
    /// <#Description#>
    public let key: String
    /// <#Description#>
    public let data: [String: AnyHashable]
    
    /// <#Description#>
    /// - Parameters:
    ///   - alt: <#alt description#>
    ///   - key: <#key description#>
    ///   - data: <#data description#>
    public init(
        alt: String,
        key: String,
        data: [String: AnyHashable]
    ) {
        self.alt = alt
        self.key = key
        self.data = data
    }
}

// MARK: - MessengerPostback + Codable

extension MessengerPostback: Codable {
    enum CodingKeys: String, CodingKey {
        case alt
        case key
        case data
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(alt, forKey: .alt)
        try container.encode(key, forKey: .key)
        try container.encode(data, forKey: .data)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        alt = try container.decode(String.self, forKey: .alt)
        key = try container.decode(String.self, forKey: .key)
        data = try container.decode([String: AnyHashable].self, forKey: .data)
    }
}
