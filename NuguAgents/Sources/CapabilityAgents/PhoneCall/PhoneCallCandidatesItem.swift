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

/// An Item received through the 'SendCandidates' directive in `PhoneCallAgent`.
public struct PhoneCallCandidatesItem {
    /// The unique identifier to specify play service.
    public let playServiceId: String
    /// The intent of candidates in `PhoneCallAgent`
    public let intent: PhoneCallIntent
    /// Types of phone-call
    public let callType: PhoneCallType?
    /// Recipient information analyzed from utterance
    public let recipientIntended: PhoneCallRecipientIntended?
    /// The candidate searched for play service.
    ///
    /// If nil, there are no search results.
    public let candidates: [PhoneCallPerson]?
    /// The scene of search target and display tempate
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
