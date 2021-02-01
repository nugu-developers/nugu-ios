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

public struct MessageCandidatesItem {
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
    public let interactionControl: InteractionControl?
}

// MARK: - MessageCandidatesItem + Codable

extension MessageCandidatesItem: Codable {
    enum CodingKeys: String, CodingKey {
        case playServiceId
        case intent
        case recipientIntended
        case searchScene
        case candidates
        case messageToSend
        case interactionControl
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        playServiceId = try container.decode(String.self, forKey: .playServiceId)
        intent = try? container.decode(String.self, forKey: .intent)
        recipientIntended = try? container.decode(MessageRecipientIntended.self, forKey: .recipientIntended)
        searchScene = try? container.decode(String.self, forKey: .searchScene)
        candidates = try? container.decode([MessageCandidatesItem].self, forKey: .candidates)
        messageToSend = try? container.decode(MessageToSendItem.self, forKey: .messageToSend)
        interactionControl = try? container.decode(InteractionControl.self, forKey: .interactionControl)
    }
}
