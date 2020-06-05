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

public struct ChipsAgentItem {
    public let playServiceId: String
    public let target: Target
    public let chips: [Chip]
    
    public enum Target: String, Decodable {
        case dialog = "DM"
    }
    
    public struct Chip {
        public let token: String
        public let textSource: String
        public let type: ItemType
        public let icon: String?
        public let text: String?
        public let image: String?
        
        public enum ItemType: String, Decodable {
            case text = "TEXT"
            case image = "IMAGE"
        }
    }
}

// MARK: - Decodable

extension ChipsAgentItem: Decodable {
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

extension ChipsAgentItem.Chip: Decodable {
    enum CodingKeys: String, CodingKey {
        case token
        case textSource
        case type
        case icon
        case text
        case image
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        token = try container.decode(String.self, forKey: .token)
        textSource = try container.decode(String.self, forKey: .textSource)
        type = try container.decode(ItemType.self, forKey: .type)
        icon = try? container.decode(String.self, forKey: .icon)
        text = try? container.decode(String.self, forKey: .text)
        image = try? container.decode(String.self, forKey: .image)
    }
}
