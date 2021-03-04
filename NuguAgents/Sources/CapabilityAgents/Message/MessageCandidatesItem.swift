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

/// An Item received through the 'SendCandidates' directive in `MessageAgent`. 
public struct MessageCandidatesItem {
    /// The unique identifier to specify play service.
    public let playServiceId: String
    /// The intent of candidates in `MessageAgent`.
    public let intent: String?
    /// Recipient information analyzed from utterance.
    public let recipientIntended: MessageRecipientIntended?
    /// The scene of search target and display tempate.
    public let searchScene: String?
    /// The candidate searched for play service.
    ///
    /// If nil, there are no search results.
    public let candidates: [Contact]?
    /// The message to be used for outgoing.
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
        candidates = try? container.decode([Contact].self, forKey: .candidates)
        messageToSend = try? container.decode(MessageToSendItem.self, forKey: .messageToSend)
        interactionControl = try? container.decode(InteractionControl.self, forKey: .interactionControl)
    }
}

// MARK: - Contact

extension MessageCandidatesItem {
    public struct Contact: Codable {
        public enum Label: String, Codable {
            case mobile = "MOBILE"
            case company = "COMPANY"
            case home = "HOME"
            case userDefined = "USER_DEFINED"
        }
        
        public enum ContactType: String, Codable {
            case contact = "CONTACT"
            case exchange = "EXCHANGE"
            case t114 = "T114"
            case none = "NONE"
        }
        
        public struct Message: Codable {
            public enum MessageType: String, Codable {
                case sms = "SMS"
                case mms = "MMS"
            }
            
            public let text: String
            public let type: MessageType
            public let time: String?
            public let numInMessageHistory: String?
            public let token: String?
            public let score: String?
            
            public init(text: String, type: MessageType, time: String?, numInMessageHistory: String?, token: String?, score: String?) {
                self.text = text
                self.type = type
                self.time = time
                self.numInMessageHistory = numInMessageHistory
                self.token = token
                self.score = score
            }
        }
        
        public let name: String?
        public let type: ContactType?
        public let number: String?
        public let profileImgUrl: String?
        public let message: Message?
        
        public init(name: String?, type: ContactType, number: String?, profileImgUrl: String?, message: Message?) {
            self.name = name
            self.type = type
            self.number = number
            self.profileImgUrl = profileImgUrl
            self.message = message
        }
    }
}
