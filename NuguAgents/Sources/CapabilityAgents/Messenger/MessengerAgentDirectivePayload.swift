//
//  MessengerAgentDirectivePayload.swift
//  NuguMessengerAgent
//
//  Created by yonghoonKwon on 2021/04/13.
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

public enum MessengerAgentDirectivePayload {
    
    // MARK: CreateSucceeded
    
    public struct CreateSucceeded: Codable {
        public let roomId: String
        public let playServiceId: String
    }
    
    // MARK: Configure
    
    public struct Configure: Codable {
        
        // MARK: Configure.Data
        
        public struct Data: Codable {
            public let uploadMenus: [String]?
            public let persistentMenus: [MessengerPersistentMenu]?
            public let enableDisplayRead: Bool?
            public let enableDisplayReaction: Bool?
            public let profiles: [MessengerProfile]?
            public let defaultProfileKey: String?
        }
        
        public let roomId: String
        public let dialogSessionId: String?
        public let playServiceId: String
        public let data: Data
    }
    
    // MARK: SendHistory
    
    public struct SendHistory: Codable {
        
        // MARK: SendHistory.Messaging
        
        public struct Messaging: Codable {
            
            // MARK: SendHistory.Messaging.Member
            
            public struct Member: Codable {
                public let memberId: String
                public let lastReadTimestamp: Int
                public let isExit: Bool
            }
            
            public let messages: [NotifyMessage]
            public let members: [Member]
        }
        
        public let roomId: String
        public let playServiceId: String
        public let messaging: Messaging
    }
    
    // MARK: NotifyMessage
    
    public struct NotifyMessage {
        public let id: String
        public let roomId: String
        public let sender: String?
        public let playServiceId: String?
        public let timestamp: Int
        public let format: String
        public let text: String?
        public let template: [String: AnyHashable]?
        public let postback: MessengerPostback?
        public let profileKey: String?
        public let disableInputForm: Bool?
    }
    
    // MARK: NotifyStartDialog
    
    public struct NotifyStartDialog: Codable {
        public let roomId: String
        public let dialogSessionId: String
        public let playServiceId: String
    }
    
    // MARK: NotifyStopDialog
    
    public struct NotifyStopDialog: Codable {
        public let roomId: String
        public let dialogSessionId: String
        public let playServiceId: String
    }
    
    // MARK: NotifyRead
    
    public struct NotifyRead: Codable {
        public let roomId: String
        public let sender: String
        public let readMessageId: String
        public let playServiceId: String
    }
    
    // MARK: NotifyReaction
    
    public struct NotifyReaction: Codable {
        public let playServiceId: String
        public let roomId: String
        public let timestamp: Int
        public let sender: String
        public let action: String
        public let profileKey: String?
        public let actionDurationInMilliseconds: Int
    }
    
    // MARK: MessageRedirect
    
    public struct MessageRedirect: Codable {
        public let text: String
        public let token: String
        public let playServiceId: String
        public let targetPlayServiceId: String?
    }
}

// MARK: - MessengerAgentDirectivePayload.NotifyMessage + Codable

extension MessengerAgentDirectivePayload.NotifyMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case roomId
        case sender
        case playServiceId
        case timestamp
        case format
        case text
        case template
        case postback
        case profileKey
        case disableInputForm
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(roomId, forKey: .roomId)
        try container.encodeIfPresent(sender, forKey: .sender)
        try container.encodeIfPresent(playServiceId, forKey: .playServiceId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(format, forKey: .format)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(template, forKey: .template)
        try container.encodeIfPresent(postback, forKey: .postback)
        try container.encodeIfPresent(profileKey, forKey: .profileKey)
        try container.encodeIfPresent(disableInputForm, forKey: .disableInputForm)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        roomId = try container.decode(String.self, forKey: .roomId)
        sender = try? container.decodeIfPresent(String.self, forKey: .sender)
        playServiceId = try? container.decodeIfPresent(String.self, forKey: .playServiceId)
        timestamp = try container.decode(Int.self, forKey: .timestamp)
        format = try container.decode(String.self, forKey: .format)
        text = try? container.decodeIfPresent(String.self, forKey: .text)
        template = try? container.decodeIfPresent([String: AnyHashable].self, forKey: .template)
        postback = try? container.decodeIfPresent(MessengerPostback.self, forKey: .postback)
        profileKey = try? container.decodeIfPresent(String.self, forKey: .profileKey)
        disableInputForm = try? container.decodeIfPresent(Bool.self, forKey: .disableInputForm)
        
    }
}
