//
//  PhoneCallPerson.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/04/29.
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
public struct PhoneCallPerson: Codable {

    // MARK: PersonType
    
    /// <#Description#>
    public enum PersonType: String, Codable {
        case contact = "CONTACT"
        case exchange = "EXCHANGE"
        case t114 = "T114"
        case none = "NONE"
    }
    
    // MARK: Address
    
    /// <#Description#>
    public struct Address: Codable {
        /// <#Description#>
        public let road: String?
        /// <#Description#>
        public let jibun: String?
        
        /// <#Description#>
        /// - Parameters:
        ///   - road: <#road description#>
        ///   - jibun: <#jibun description#>
        public init(road: String?, jibun: String?) {
            self.road = road
            self.jibun = jibun
        }
    }
    
    // MARK: BusinessHours
    
    /// <#Description#>
    public struct BusinessHours: Codable {
        /// <#Description#>
        public let open: String?
        /// <#Description#>
        public let close: String?
        /// <#Description#>
        public let info: String?
        
        /// <#Description#>
        /// - Parameters:
        ///   - open: <#open description#>
        ///   - close: <#close description#>
        ///   - info: <#info description#>
        public init(open: String?, close: String?, info: String?) {
            self.open = open
            self.close = close
            self.info = info
        }
    }
    
    // MARK: History
    
    /// <#Description#>
    public struct History: Codable {
        
        /// <#Description#>
        public enum HistoryType: String, Codable {
            case out = "OUT"
            case outCanceled = "OUT_CANCELED"
            case incoming = "IN"
            case rejected = "REJECTED"
            case missed = "MISSED"
            case blocked = "BLOCKED"
        }
        
        /// <#Description#>
        public enum CallType: String, Codable {
            case normal = "NORMAL"
            case video = "VIDEO"
            case callar = "CALLAR"
            case group = "GROUP"
            case voiceMessage = "VOICE_MESSAGE"
        }
        
        /// <#Description#>
        public let time: String?
        /// <#Description#>
        public let type: HistoryType?
        /// <#Description#>
        public let callType: CallType?
        
        /// <#Description#>
        /// - Parameters:
        ///   - time: <#time description#>
        ///   - type: <#type description#>
        ///   - callType: <#callType description#>
        public init(time: String?, type: HistoryType?, callType: CallType?) {
            self.time = time
            self.type = type
            self.callType = callType
        }
    }
    
    // MARK: Contact
    
    /// <#Description#>
    public struct Contact {
        
        /// <#Description#>
        public enum Label: String, Codable {
            case mobile = "MOBILE"
            case company = "COMPANY"
            case home = "HOME"
            case userDefined = "USER_DEFINED"
        }
        
        /// <#Description#>
        public let label: Label?
        /// <#Description#>
        public let number: String?
        /// <#Description#>
        public let isBlocked: Bool?
        
        /// <#Description#>
        /// - Parameters:
        ///   - label: <#label description#>
        ///   - number: <#number description#>
        public init(label: Label?, number: String?, isBlocked: Bool?) {
            self.label = label
            self.number = number
            self.isBlocked = isBlocked
        }
    }
    
    /// <#Description#>
    public let name: String
    /// <#Description#>
    public let type: PersonType
    /// <#Description#>
    public let profileImgUrl: String?
    /// <#Description#>
    public let category: String?
    /// <#Description#>
    public let address: Address?
    /// <#Description#>
    public let businessHours: BusinessHours?
    /// <#Description#>
    public let history: History?
    /// <#Description#>
    public let numInCallHistory: String?
    /// <#Description#>
    public let poiId: String?
    /// <#Description#>
    public let token: String?
    /// <#Description#>
    public let score: String?
    /// <#Description#>
    public let contacts: [Contact]?
    
    /// <#Description#>
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - type: <#type description#>
    ///   - profileImgUrl: <#profileImgUrl description#>
    ///   - category: <#category description#>
    ///   - address: <#address description#>
    ///   - businessHours: <#businessHours description#>
    ///   - history: <#history description#>
    ///   - numInCallHistory: <#numInCallHistory description#>
    ///   - poiId: <#poiId description#>
    ///   - token: <#token description#>
    ///   - score: <#score description#>
    ///   - contacts: <#contacts description#>
    public init(
        name: String,
        type: PersonType,
        profileImgUrl: String?,
        category: String?,
        address: Address?,
        businessHours: BusinessHours?,
        history: History?,
        numInCallHistory: String?,
        poiId: String?,
        token: String?,
        score: String?,
        contacts: [Contact]?
    ) {
        self.name = name
        self.type = type
        self.profileImgUrl = profileImgUrl
        self.category = category
        self.address = address
        self.businessHours = businessHours
        self.history = history
        self.numInCallHistory = numInCallHistory
        self.poiId = poiId
        self.token = token
        self.score = score
        self.contacts = contacts
    }
}

// MARK: - PhoneCallPerson.Contact + Codable

extension PhoneCallPerson.Contact: Codable {
    enum CodingKeys: String, CodingKey {
        case label
        case number
        case isBlocked
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(number, forKey: .number)
        
        if let isBlockedValue = isBlocked {
            try container.encodeIfPresent(isBlockedValue ? "TRUE": "FALSE", forKey: .isBlocked)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        label = try? container.decodeIfPresent(Label.self, forKey: .label)
        number = try? container.decodeIfPresent(String.self, forKey: .number)
        let isBlockString = try? container.decodeIfPresent(String.self, forKey: .isBlocked)
        if isBlockString == "TRUE" {
            isBlocked = true
        } else {
            isBlocked = false
        }
    }
}
