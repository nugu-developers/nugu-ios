//
//  AudioPlayerPlaylist.swift
//  NuguAgents
//
//  Copyright © 2023 SK Telecom Co., Ltd. All rights reserved.
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

public struct AudioPlayerPlaylist: Codable {
    public struct TextObject: Codable {
        public let text: String?
        public let size: String?
        public let maxLine: Int?
    }
    
    public struct PlaylistTitle: Codable {
        public let iconUrl: String?
        public let text: TextObject?
    }
    
    public struct PlaylistItems: Codable {
        public struct Item: Codable {
            public struct Favorite: Codable {
                private enum CodingKeys: CodingKey {
                    case text
                    case imageUrl
                    case status
                    case token
                    case postback
                }
                
                public let text: TextObject?
                public let imageUrl: String?
                public var status: Bool?
                public let token: String
                public let postback: [String: AnyHashable]?
                
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    text = try container.decodeIfPresent(TextObject.self, forKey: .text)
                    imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
                    status = try container.decodeIfPresent(Bool.self, forKey: .status)
                    token = try container.decode(String.self, forKey: .token)
                    postback = try container.decodeIfPresent([String: AnyHashable].self, forKey: .postback)
                }
                
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encodeIfPresent(text, forKey: .text)
                    try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
                    try container.encodeIfPresent(status, forKey: .status)
                    try container.encode(token, forKey: .token)
                    try container.encodeIfPresent(postback, forKey: .postback)
                }
            }
            
            private enum CodingKeys: String, CodingKey {
                case text
                case subText
                case imageUrl
                case badgeUrl
                case badgeMessage
                case available
                case token
                case postback
                case favorite
                case libraryAvailable
            }
            
            public let text: TextObject?
            public let subText: TextObject?
            public let imageUrl: String?
            public let badgeUrl: String?
            public let badgeMessage: String?
            public let available: Bool?
            public let token: String
            public let postback: [String: AnyHashable]?
            public var favorite: Favorite?
            public let libraryAvailable: Bool?
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                text = try container.decodeIfPresent(TextObject.self, forKey: .text)
                subText = try container.decodeIfPresent(TextObject.self, forKey: .subText)
                imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
                badgeUrl = try container.decodeIfPresent(String.self, forKey: .badgeUrl)
                badgeMessage = try container.decodeIfPresent(String.self, forKey: .badgeMessage)
                available = try container.decodeIfPresent(Bool.self, forKey: .available)
                token = try container.decode(String.self, forKey: .token)
                postback = try container.decodeIfPresent([String: AnyHashable].self, forKey: .postback)
                favorite = try container.decodeIfPresent(Favorite.self, forKey: .favorite)
                libraryAvailable = try container.decodeIfPresent(Bool.self, forKey: .libraryAvailable)
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(text, forKey: .text)
                try container.encodeIfPresent(subText, forKey: .subText)
                try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
                try container.encodeIfPresent(badgeUrl, forKey: .badgeUrl)
                try container.encodeIfPresent(badgeMessage, forKey: .badgeMessage)
                try container.encodeIfPresent(available, forKey: .available)
                try container.encode(token, forKey: .token)
                try container.encodeIfPresent(postback, forKey: .postback)
                try container.encodeIfPresent(favorite, forKey: .favorite)
            }
        }
        
        public let replaceType: String?
        public var items: [Item]
    }
    
    public let type: String?
    public let title: PlaylistTitle?
    public let subTitle: PlaylistTitle?
    public let token: String?
    public let edit: PlaylistTitle?
    public let button: DisplayCommonTemplate.Common.Button?
    public var currentToken: String?
    public var list: PlaylistItems?
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(subTitle, forKey: .subTitle)
        try container.encodeIfPresent(token, forKey: .token)
        try container.encodeIfPresent(edit, forKey: .edit)
        try container.encodeIfPresent(currentToken, forKey: .currentToken)
        try container.encodeIfPresent(list, forKey: .list)
    }
}
