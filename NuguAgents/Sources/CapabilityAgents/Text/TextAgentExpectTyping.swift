//
//  TextAgentExpectTyping.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 17/06/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
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

struct TextAgentExpectTyping: Decodable {
    let messageId: String
    let dialogRequestId: String
    let payload: Payload
}

// MARK: - TextAgentExpectTyping.Payload

extension TextAgentExpectTyping {
    struct Payload: Decodable {
        let playServiceId: String?
        let domainTypes: [AnyHashable]?
        let asrContext: [String: AnyHashable]?
        
        enum CodingKeys: String, CodingKey {
            case playServiceId
            case domainTypes
            case asrContext
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            playServiceId = try? container.decode(String.self, forKey: .playServiceId)
            domainTypes = try? container.decode([AnyHashable].self, forKey: .domainTypes)
            asrContext = try? container.decodeIfPresent([String: AnyHashable].self, forKey: .asrContext)
        }
    }
}
