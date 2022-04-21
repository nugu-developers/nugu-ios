//
//  PhoneCallAgentContext.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/10/19.
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
public struct PhoneCallAgentContext {
    
    /// <#Description#>
    public struct Template {
        /// <#Description#>
        public let intent: PhoneCallIntent?
        /// <#Description#>
        public let callType: PhoneCallType?
        /// <#Description#>
        public let recipientIntended: PhoneCallRecipientIntended?
        /// <#Description#>
        public let candidates: [PhoneCallPerson]?
        /// <#Description#>
        public let searchScene: String?
        
        /// The initializer for `PhoneCallAgentContext.Template`.
        /// - Parameters:
        ///   - intent: <#intent description#>
        ///   - callType: <#callType description#>
        ///   - recipientIntended: <#recipientIntended description#>
        ///   - candidates: <#candidates description#>
        ///   - searchScene: <#searchScene description#>
        public init(
            intent: PhoneCallIntent?,
            callType: PhoneCallType?,
            recipientIntended: PhoneCallRecipientIntended?,
            candidates: [PhoneCallPerson]?,
            searchScene: String?
        ) {
            self.intent = intent
            self.callType = callType
            self.recipientIntended = recipientIntended
            self.candidates = candidates
            self.searchScene = searchScene
        }
    }

    /// <#Description#>
    public struct Recipient {
        /// <#Description#>
        public let name: String?
        /// <#Description#>
        public let token: String?
        /// <#Description#>
        public let isMobile: Bool?
        /// <#Description#>
        public let isRecentMissed: Bool?
        
        /// The initializer for `PhoneCallAgentContext.Recipient`.
        /// - Parameters:
        ///   - name: <#name description#>
        ///   - token: <#token description#>
        ///   - isMobile: <#isMobile description#>
        ///   - isRecentMissed: <#isRecentMissed description#>
        public init(
            name: String?,
            token: String?,
            isMobile: Bool?,
            isRecentMissed: Bool?
        ) {
            self.name = name
            self.token = token
            self.isMobile = isMobile
            self.isRecentMissed = isRecentMissed
        }
    }
    
    /// <#Description#>
    public let state: PhoneCallState
    /// <#Description#>
    public let template: PhoneCallAgentContext.Template?
    /// <#Description#>
    public let recipient: PhoneCallAgentContext.Recipient?
    /// <#Description#>
    public let numberBlockable: Bool?
    
    /// The initializer for `PhoneCallAgentContext`.
    public init(
        state: PhoneCallState,
        template: PhoneCallAgentContext.Template?,
        recipient: PhoneCallAgentContext.Recipient?,
        numberBlockable: Bool?
    ) {
        self.state = state
        self.template = template
        self.recipient = recipient
        self.numberBlockable = numberBlockable
    }
}

// MARK: - PhoneCallAgentContext + Codable

extension PhoneCallAgentContext: Codable {
    enum CodingKeys: String, CodingKey {
        case state
        case template
        case recipient
        case numberBlockable
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(template, forKey: .template)
        try container.encodeIfPresent(recipient, forKey: .recipient)
        
        if let numberBlockableValue = numberBlockable {
            try container.encodeIfPresent(numberBlockableValue ? "TRUE": "FALSE", forKey: .numberBlockable)
        }
    }
}

// MARK: - PhoneCallAgentContext.Template + Codable

extension PhoneCallAgentContext.Template: Codable {}

// MARK: - PhoneCallAgentContext.Recipient + Codable

extension PhoneCallAgentContext.Recipient: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case token
        case isMobile
        case isRecentMissed
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(token, forKey: .token)
        
        if let isMobileValue = isMobile {
            try container.encodeIfPresent(isMobileValue ? "TRUE": "FALSE", forKey: .isMobile)
        }
        
        if let isRecentMissedValue = isRecentMissed {
            try container.encodeIfPresent(isRecentMissedValue ? "TRUE": "FALSE", forKey: .isMobile)
        }
    }
}
