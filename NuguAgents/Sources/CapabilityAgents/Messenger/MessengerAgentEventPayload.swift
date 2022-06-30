//
//  MessengerAgentEventPayload.swift
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

public enum MessengerAgentEventPayload {
    
    // MARK: Sync
    
    public struct Sync {
        /// <#Description#>
        public let roomId: String
        /// <#Description#>
        public let baseTimestamp: Int
        /// <#Description#>
        public let direction: String
        /// <#Description#>
        public let num: Int?
        
        /// <#Description#>
        /// - Parameters:
        ///   - roomId: <#roomId description#>
        ///   - baseTimestamp: <#baseTimestamp description#>
        ///   - direction: <#direction description#>
        ///   - num: <#num description#>
        public init(
            roomId: String,
            baseTimestamp: Int,
            direction: String,
            num: Int?
        ) {
            self.roomId = roomId
            self.baseTimestamp = baseTimestamp
            self.direction = direction
            self.num = num
        }
    }
    
    public struct Enter {
        /// <#Description#>
        public enum EnterType: String {
            case manual = "MANUAL"
            case transfer = "TRANSFER"
        }
        
        /// <#Description#>
        public let roomId: String
        /// <#Description#>
        public let enterType: EnterType
        
        /// <#Description#>
        /// - Parameters:
        ///   - roomId: <#roomId description#>
        ///   - enterType: <#enterType description#>
        public init(roomId: String, enterType: EnterType) {
            self.roomId = roomId
            self.enterType = enterType
        }
    }
    
    // MARK: Message
    
    public struct Message {
        /// <#Description#>
        public let roomId: String
        /// <#Description#>
        public let id: String
        /// <#Description#>
        public let timestamp: Int
        /// <#Description#>
        public let format: String?
        /// <#Description#>
        public let text: String?
        /// <#Description#>
        public let template: [String: AnyHashable]?
        /// <#Description#>
        public let postback: MessengerPostback?
        
        /// <#Description#>
        /// - Parameters:
        ///   - roomId: <#roomId description#>
        ///   - id: <#id description#>
        ///   - timestamp: <#timestamp description#>
        ///   - format: <#format description#>
        ///   - text: <#text description#>
        ///   - template: <#template description#>
        ///   - postback: <#postback description#>
        public init(
            roomId: String,
            id: String,
            timestamp: Int,
            format: String?,
            text: String?,
            template: [String: AnyHashable]?,
            postback: MessengerPostback?
        ) {
            self.roomId = roomId
            self.id = id
            self.timestamp = timestamp
            self.format = format
            self.text = text
            self.template = template
            self.postback = postback
        }
    }
    
    // MARK: Reaction
    
    public struct Reaction {
        /// <#Description#>
        public let roomId: String
        /// <#Description#>
        public let timestamp: Int?
        /// <#Description#>
        public let action: String
        /// <#Description#>
        public let actionDurationInMilliseconds: Int?
        
        /// <#Description#>
        /// - Parameters:
        ///   - roomId: <#roomId description#>
        ///   - timestamp: <#action description#>
        ///   - action: <#action description#>
        ///   - actionDurationInMilliseconds: <#actionDurationInMilliseconds description#>
        public init(
            roomId: String,
            timestamp: Int?,
            action: String,
            actionDurationInMilliseconds: Int?
        ) {
            self.roomId = roomId
            self.timestamp = timestamp
            self.action = action
            self.actionDurationInMilliseconds = actionDurationInMilliseconds
        }
    }
}

// MARK: - MessengerAgentEventPayload.Sync + Codable

extension MessengerAgentEventPayload.Sync: Codable {}

// MARK: - MessengerAgentEventPayload.Enter + Codable

extension MessengerAgentEventPayload.Enter: Codable {}

// MARK: - MessengerAgentEventPayload.Enter.EnterType + Codable

extension MessengerAgentEventPayload.Enter.EnterType: Codable {}

// MARK: - MessengerAgentEventPayload.Message + Codable

extension MessengerAgentEventPayload.Message: Codable {
    enum CodingKeys: String, CodingKey {
        case roomId
        case id
        case timestamp
        case format
        case text
        case template
        case postback
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(roomId, forKey: .roomId)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(format, forKey: .format)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(template, forKey: .template)
        try container.encodeIfPresent(postback, forKey: .postback)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        roomId = try container.decode(String.self, forKey: .roomId)
        id = try container.decode(String.self, forKey: .id)
        timestamp = try container.decode(Int.self, forKey: .timestamp)
        format = try? container.decodeIfPresent(String.self, forKey: .format)
        text = try? container.decodeIfPresent(String.self, forKey: .text)
        template = try? container.decodeIfPresent([String: AnyHashable].self, forKey: .template)
        postback = try? container.decodeIfPresent(MessengerPostback.self, forKey: .postback)
    }
}

// MARK: - MessengerAgentEventPayload.Reaction + Codable

extension MessengerAgentEventPayload.Reaction: Codable {}
