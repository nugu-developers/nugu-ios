//
//  MessageAgentContext.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/01/06.
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
public struct MessageAgentContext: Codable {
    /// <#Description#>
    public struct Template: Codable {
        /// <#Description#>
        public let info: String?
        /// <#Description#>
        public let recipientIntended: MessageRecipientIntended?
        /// <#Description#>
        public let searchScene: String?
        /// <#Description#>
        public let candidates: [MessageAgentContact]?
        /// <#Description#>
        public let messageToSend: MessageToSendItem?
        
        /// The initializer for `MessageAgentContext`.
        /// - Parameters:
        ///   - info: <#info description#>
        ///   - recipientIntended: <#recipientIntended description#>
        ///   - searchScene: <#searchScene description#>
        ///   - candidates: <#candidates description#>
        ///   - messageToSend: <#messageToSend description#>
        public init(
            info: String?,
            recipientIntended: MessageRecipientIntended?,
            searchScene: String?,
            candidates: [MessageAgentContact]?,
            messageToSend: MessageToSendItem?
        ) {
            self.info = info
            self.recipientIntended = recipientIntended
            self.searchScene = searchScene
            self.candidates = candidates
            self.messageToSend = messageToSend
        }
    }
    
    /// <#Description#>
    public let readActivity: String
    /// <#Description#>
    public let token: String?
    /// <#Description#>
    public let template: Template?
    
    /// <#Description#>
    /// - Parameters:
    ///   - readActivity: <#readActivity description#>
    ///   - token: <#token description#>
    ///   - template: <#template description#>
    public init(
        readActivity: String,
        token: String?,
        template: Template?
    ) {
        self.readActivity = readActivity
        self.token = token
        self.template = template
    }
}
