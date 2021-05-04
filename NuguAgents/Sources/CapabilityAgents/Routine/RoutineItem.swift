//
//  RoutineItem.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/07/07.
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

import NuguUtils

struct RoutineItem {
    let dialogRequestId: String
    let messageId: String
    let payload: Payload

    struct Payload: Decodable {
        let playServiceId: String
        let token: String
        let actions: [Action]

        struct Action {
            let type: String
            let text: String?
            let data: [String: AnyHashable]?
            let playServiceId: String?
            let token: String?
            let postDelayInMilliseconds: Int?

            var actionType: Type? {
                Type.init(rawValue: type)
            }

            enum `Type`: String, Decodable {
                case text = "TEXT"
                case data = "DATA"
            }
        }

    }
}

extension RoutineItem.Payload.Action {
    var postDelay: TimeIntervallic? {
        guard let postDelayInMilliseconds = postDelayInMilliseconds else { return nil }

        return NuguTimeInterval(milliseconds: postDelayInMilliseconds)
    }
}

// MARK: - RoutineItem.Payload.Action: Decodable
extension RoutineItem.Payload.Action: Decodable {
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case data
        case playServiceId
        case token
        case postDelayInMilliseconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decode(String.self, forKey: .type)
        text = try? container.decode(String.self, forKey: .text)
        data = try? container.decode([String: AnyHashable].self, forKey: .data)
        playServiceId = try? container.decode(String.self, forKey: .playServiceId)
        token = try? container.decode(String.self, forKey: .token)
        postDelayInMilliseconds = try? container.decode(Int.self, forKey: .postDelayInMilliseconds)
    }
}
