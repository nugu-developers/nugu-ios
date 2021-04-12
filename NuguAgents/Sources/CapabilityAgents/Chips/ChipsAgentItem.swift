//
//  ChipsAgentItem.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/05/26.
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
public struct ChipsAgentItem {
    /// <#Description#>
    public let playServiceId: String
    /// <#Description#>
    public let target: Target
    /// <#Description#>
    public let chips: [Chip]
    
    /// <#Description#>
    public enum Target: String, Codable {
        case dialog = "DM"
        case listen = "LISTEN"
        case speaking = "SPEAKING"
    }
    
    /// <#Description#>
    public struct Chip {
        /// <#Description#>
        public let type: ItemType?
        /// <#Description#>
        public let text: String
        /// <#Description#>
        public let token: String?
        
        /// <#Description#>
        public enum ItemType: String, Codable {
            case nudge = "NUDGE"
            case action = "ACTION"
            case general = "GENERAL"
        }
    }
}

// MARK: - Codable

extension ChipsAgentItem: Codable {
    enum CodingKeys: String, CodingKey {
        case playServiceId
        case target
        case chips
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        playServiceId = try container.decode(String.self, forKey: .playServiceId)
        target = try container.decode(Target.self, forKey: .target)
        chips = try container.decode([Chip].self, forKey: .chips)
    }
}

extension ChipsAgentItem.Chip: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case token
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try? container.decode(ItemType.self, forKey: .type)
        text = try container.decode(String.self, forKey: .text)
        token = try? container.decode(String.self, forKey: .token)
    }
}

// MARK: - Equatable

extension ChipsAgentItem.Chip: Equatable {}
