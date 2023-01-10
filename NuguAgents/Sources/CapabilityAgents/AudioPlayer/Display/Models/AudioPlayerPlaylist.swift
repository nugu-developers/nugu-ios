//
//  AudioPlayerPlaylist.swift
//  NuguAgents
//
//  Copyright © 2023 SK Telecom Co., Ltd. All rights reserved.
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
                enum CodingKeys: CodingKey {
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
            
            enum CodingKeys: String, CodingKey {
                case text = "text"
                case subText
                case imageUrl
                case badgeUrl
                case badgeMessage
                case available
                case token
                case postback
                case favorite
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
    
    enum CodingKeys: CodingKey {
        case type
        case title
        case subTitle
        case token
        case edit
        case button
        case currentToken
        case list
    }
    
    public let type: String?
    public let title: PlaylistTitle?
    public let subTitle: PlaylistTitle?
    public let token: String?
    public let edit: PlaylistTitle?
    public let button: DisplayCommonTemplate.Common.Button?
    public let currentToken: String?
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
