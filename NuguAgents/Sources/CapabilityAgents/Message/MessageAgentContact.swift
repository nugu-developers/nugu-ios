//
//  MessageAgentContact.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/01/07.
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
public struct MessageAgentContact: Codable {
    
    /// <#Description#>
    public enum ContactType: String, Codable {
        case contact = "CONTACT"
        case exchange = "EXCHANGE"
        case t114 = "T114"
        case none = "NONE"
        case emergency = "EMERGENCY"
    }
    
    /// <#Description#>
    public enum Label: String, Codable {
        case mobile = "MOBILE"
        case company = "COMPANY"
        case home = "HOME"
        case userDefined = "USER_DEFINED"
    }
    
    /// <#Description#>
    public struct Message: Codable {
        
        /// <#Description#>
        public enum MessageType: String, Codable {
            case sms = "SMS"
            case mms = "MMS"
        }
        
        /// <#Description#>
        public let text: String
        /// <#Description#>
        public let type: MessageType?
        
        /// The initializer for `MessageAgentContact.Message`.
        /// - Parameters:
        ///   - text: <#text description#>
        ///   - type: <#type description#>
        public init(text: String, type: MessageType?) {
            self.text = text
            self.type = type
        }
    }
    
    /// <#Description#>
    public let name: String?
    /// <#Description#>
    public let type: ContactType?
    /// <#Description#>
    public let number: String?
    /// <#Description#>
    public let label: Label?
    /// <#Description#>
    public let profileImgUrl: String?
    /// <#Description#>
    public let message: Message?
    /// <#Description#>
    public let time: String?
    /// <#Description#>
    public let numInMessageHistory: String?
    /// <#Description#>
    public let token: String?
    /// <#Description#>
    public let score: String?
    
    /// The initializer for `MessageAgentContact`.
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - type: <#type description#>
    ///   - number: <#number description#>
    ///   - label: <#label description#>
    ///   - profileImgUrl: <#profileImgUrl description#>
    ///   - message: <#message description#>
    ///   - time: <#time description#>
    ///   - numInMessageHistory: <#numInMessageHistory description#>
    ///   - token: <#token description#>
    ///   - score: <#score description#>
    public init(
        name: String?,
        type: ContactType?,
        number: String?,
        label: Label?,
        profileImgUrl: String?,
        message: Message?,
        time: String?,
        numInMessageHistory: String?,
        token: String?,
        score: String?
    ) {
        self.name = name
        self.type = type
        self.number = number
        self.label = label
        self.profileImgUrl = profileImgUrl
        self.message = message
        self.time = time
        self.numInMessageHistory = numInMessageHistory
        self.token = token
        self.score = score
    }
}
