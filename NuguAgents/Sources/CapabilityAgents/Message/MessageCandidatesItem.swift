//
//  MessageCandidatesItem.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/01/08.
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

public struct MessageCandidatesItem: Codable {
    /// <#Description#>
    public let playServiceId: String
    /// <#Description#>
    public let intent: String?
    /// <#Description#>
    public let recipientIntended: MessageRecipientIntended?
    /// <#Description#>
    public let searchScene: String?
    /// <#Description#>
    public let candidates: [MessageCandidatesItem]?
    /// <#Description#>
    public let messageToSend: MessageToSendItem?
    
    /// <#Description#>
    /// - Parameters:
    ///   - playServiceId: <#playServiceId description#>
    ///   - intent: <#intent description#>
    ///   - recipientIntended: <#recipientIntended description#>
    ///   - searchScene: <#searchScene description#>
    ///   - candidates: <#candidates description#>
    ///   - messageToSend: <#messageToSend description#>
    public init(
        playServiceId: String,
        intent: String?,
        recipientIntended: MessageRecipientIntended?,
        searchScene: String?,
        candidates: [MessageCandidatesItem]?,
        messageToSend: MessageToSendItem?
    ) {
        self.playServiceId = playServiceId
        self.intent = intent
        self.recipientIntended = recipientIntended
        self.searchScene = searchScene
        self.candidates = candidates
        self.messageToSend = messageToSend
    }
}
