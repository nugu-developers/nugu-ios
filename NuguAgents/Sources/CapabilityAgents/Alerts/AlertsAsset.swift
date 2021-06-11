//
//  AlertsAsset.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/03/05.
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

import Foundation

/// <#Description#>
public struct AlertsAsset: Codable {
    /// <#Description#>
    public let type: String
    /// <#Description#>
    public let resourceDictionary: [String: AnyHashable]?
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - resource: <#resource description#>
    public init(
        type: String,
        resourceDictionary: [String: AnyHashable]? = nil
    ) {
        self.type = type
        self.resourceDictionary = resourceDictionary
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case resource
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try container.decode(String.self, forKey: .type)
        switch type {
        case "Routine.Start":
            resourceDictionary = try? container.decode([String: AnyHashable].self, forKey: .resource)
        default:
            resourceDictionary = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        switch type {
        case "Routine.Start":
            try container.encodeIfPresent(resourceDictionary, forKey: .resource)
        default:
            break
        }
    }
}
