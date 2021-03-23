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
public struct PhoneCallCandidatesItem: Codable {
    
    // MARK: SearchTarget
    
    /// <#Description#>
    public enum SearchTarget: Codable {
        case contact
        case exchange
        case t114
        case unknown
        
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
    
    /// <#Description#>
    /// - Parameters:
    ///   - playServiceId: <#playServiceId description#>
    ///   - intent: <#intent description#>
    ///   - callType: <#callType description#>
    ///   - recipientIntended: <#recipientIntended description#>
    ///   - candidates: <#candidates description#>
    ///   - searchScene: <#searchScene description#>
    public init(
        playServiceId: String,
        intent: PhoneCallIntent,
        callType: PhoneCallType?,
        recipientIntended: PhoneCallRecipientIntended?,
        candidates: [PhoneCallPerson]?,
        searchScene: String?
    ) {
        self.playServiceId = playServiceId
        self.intent = intent
        self.callType = callType
        self.recipientIntended = recipientIntended
        self.candidates = candidates
        self.searchScene = searchScene
        self.interactionControl = nil
    }
}
