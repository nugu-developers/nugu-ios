//
//  MessengerPersistentMenu.swift
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

public struct MessengerPersistentMenu {
    
    // MARK: ActionType
    
    public enum ActionType: String {
        case postback = "POSTBACK"
        case text = "TEXT"
        case deeplinkIn = "DEEPLINK_IN"
        case deeplinkOut = "DEEPLINK_OUT"
    }
    
    public let iconUrl: String?
    public let label: String
    public let actionType: ActionType
    public let postback: MessengerPostback?
    public let text: String?
    public let url: String?
    
}

// MARK: - MessengerPersistentMenu + Codable

extension MessengerPersistentMenu: Codable {
    enum CodingKeys: String, CodingKey {
        case iconUrl
        case label
        case actionType
        case postback
        case text
        case url
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(iconUrl, forKey: .iconUrl)
        try container.encode(label, forKey: .label)
        try container.encode(actionType, forKey: .actionType)
        try container.encodeIfPresent(postback, forKey: .postback)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(url, forKey: .url)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        iconUrl = try? container.decodeIfPresent(String.self, forKey: .iconUrl)
        label = try container.decode(String.self, forKey: .label)
        actionType = try container.decode(ActionType.self, forKey: .actionType)
        postback = try? container.decodeIfPresent(MessengerPostback.self, forKey: .postback)
        text = try? container.decodeIfPresent(String.self, forKey: .text)
        url = try? container.decodeIfPresent(String.self, forKey: .url)
    }
}

// MARK: - MessengerPersistentMenu.ActionType + Codable

extension MessengerPersistentMenu.ActionType: Codable {}
