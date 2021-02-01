//
//  PhoneCallCandidatesItem.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/07/01.
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
public struct PhoneCallCandidatesItem {
    
    // MARK: SearchTarget
    
    /// <#Description#>
    public enum SearchTarget {
        case contact
        case exchange
        case t114
        case unknown
    }
    
    /// <#Description#>
    public let playServiceId: String
    /// <#Description#>
    public let intent: PhoneCallIntent
    /// <#Description#>
    public let callType: PhoneCallType?
    /// <#Description#>
    public let recipientIntended: PhoneCallRecipientIntended?
    /// <#Description#>
    public let candidates: [PhoneCallPerson]?
    /// <#Description#>
    public let searchScene: String?
    /// <#Description#>
    public let interactionControl: InteractionControl?
}

// MARK: - PhoneCallCandidatesItem + Codable

extension PhoneCallCandidatesItem: Codable {
    enum CodingKeys: String, CodingKey {
        case playServiceId
        case intent
        case callType
        case recipientIntended
        case candidates
        case searchScene
        case interactionControl
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        playServiceId = try container.decode(String.self, forKey: .playServiceId)
        intent = try container.decode(PhoneCallIntent.self, forKey: .intent)
        callType = try? container.decode(PhoneCallType.self, forKey: .callType)
        recipientIntended = try? container.decode(PhoneCallRecipientIntended.self, forKey: .recipientIntended)
        candidates = try? container.decode([PhoneCallPerson].self, forKey: .candidates)
        searchScene = try? container.decode(String.self, forKey: .searchScene)
        interactionControl = try? container.decode(InteractionControl.self, forKey: .interactionControl)
    }
}

// MARK: - PhoneCallCandidatesItem.SearchTarget + Codable

extension PhoneCallCandidatesItem.SearchTarget: Codable {
    enum CodingKeys: CodingKey {
        case contact, exchange, t114, unknown
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        let value = try container.decode(String.self)
        switch value {
        case "CONTACT": self = .contact
        case "EXCHANGE": self = .exchange
        case "T114": self = .t114
        default: self = .unknown
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .contact:
            try container.encode("CONTACT")
        case .exchange:
            try container.encode("EXCHANGE")
        case .t114:
            try container.encode("T114")
        case .unknown:
            try container.encode("UNKNOWN")
        }
    }
}
