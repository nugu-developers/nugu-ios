//
//  DisplayRedirectTriggerChildPayload.swift
//  NuguAgents
//
//  Created by 김진님/AI Assistant개발 Cell on 2021/10/20.
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

public struct DisplayRedirectTriggerChildPayload {
    let playServiceId: String
    let targetPlayServiceId: String
    let parentToken: String
    let data: [String: AnyHashable]
}

// MARK: - Codable

extension DisplayRedirectTriggerChildPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case playServiceId
        case targetPlayServiceId
        case parentToken
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)        
        playServiceId = try container.decode(String.self, forKey: .playServiceId)
        targetPlayServiceId = try container.decode(String.self, forKey: .targetPlayServiceId)
        parentToken = try container.decode(String.self, forKey: .parentToken)
        data = try container.decode([String: AnyHashable].self, forKey: .data)
    }
}
