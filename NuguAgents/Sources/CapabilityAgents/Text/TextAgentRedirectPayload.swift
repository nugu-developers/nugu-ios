//
//  TextAgentRedirectPayload.swift
//  NuguAgents
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/11/23.
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

struct TextAgentRedirectPayload: Decodable {
    let text: String
    let token: String
    let source: String?
    let playServiceId: String
    let targetPlayServiceId: String?
    let interactionControl: InteractionControl?
    let service: [String: AnyHashable]?
    
    enum CodingKeys: String, CodingKey {
        case text
        case token
        case source
        case playServiceId
        case targetPlayServiceId
        case interactionControl
        case service
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        token = try container.decode(String.self, forKey: .token)
        source = try? container.decodeIfPresent(String.self, forKey: .source)
        playServiceId = try container.decode(String.self, forKey: .playServiceId)
        targetPlayServiceId = try? container.decodeIfPresent(String.self, forKey: .targetPlayServiceId)
        interactionControl = try? container.decodeIfPresent(InteractionControl.self, forKey: .interactionControl)
        service = try? container.decodeIfPresent([String: AnyHashable].self, forKey: .service)
    }
}
