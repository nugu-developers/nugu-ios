//
//  PhoneCallAgentDirectivePayload.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/03/15.
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

public enum PhoneCallAgentDirectivePayload {
    
    /// An Item received through the 'SendCandidates' directive in `PhoneCallAgent`.
    public struct SendCandidates {
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
    
    /// An Item received through the 'MakeCall' directive in `PhoneCallAgent`.
    public struct MakeCall {
        /// The unique identifier to specify play service.
        public let playServiceId: String
        /// <#Description#>
        public let recipient: PhoneCallPerson
        /// <#Description#>
        public let callType: PhoneCallType
    }
    
    /// An Item received through the 'BlockNumber' directive in `PhoneCallAgent`.
    public struct BlockNumber {
        public enum BlockType: String, Codable {
            case exact = "EXACT"
            case prefix = "PREFIX"
            case postfix = "POSTFIX"
        }
        
        /// The unique identifier to specify play service.
        public let playServiceId: String
        /// <#Description#>
        public let number: String
        /// <#Description#>
        public let blockType: BlockType
    }
}

// MARK: - PhoneCallAgentDirectivePayload.SendCandidates + Codable

extension PhoneCallAgentDirectivePayload.SendCandidates: Codable {}

// MARK: - PhoneCallAgentDirectivePayload.MakeCall + Codable

extension PhoneCallAgentDirectivePayload.MakeCall: Codable {}

// MARK: - PhoneCallAgentDirectivePayload.BlockNumber + Codable

extension PhoneCallAgentDirectivePayload.BlockNumber: Codable {}
