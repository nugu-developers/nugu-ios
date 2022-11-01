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

public struct RoutineItem {
    public let dialogRequestId: String
    public let messageId: String
    public let payload: Payload

    public struct Payload: Decodable {
        public let playServiceId: String
        public let token: String
        /**
         Name of routine
         
         Used to show the name of the current routine on devices with a display
         */
        public let name: String?
        /// Unique routine id
        public let routineId: String?
        /// The type related to `trigger`
        public let routineType: RoutineType?
        /// Routine service exposure type
        public let routineListType: RoutineListType?
        /// Actions that make up the routine
        public let actions: [Action]
        /// TextInput Source
        public let source: String?
    }
}

public extension RoutineItem.Payload {
    struct Action: Decodable {
        public let type: ActionType
        public let text: String?
        public let data: [String: AnyHashable]?
        public let playServiceId: String?
        public let token: String
        public let postDelayInMilliseconds: Int?
        public let muteDelayInMilliseconds: Int?
        public let actionTimeoutInMilliseconds: Int?
        
        @available(*, deprecated, message: "No longer needed. It will be removed in 1.9.0")
        public var actionType: ActionType? { type }

        public enum ActionType: String, Decodable {
            case text = "TEXT"
            case data = "DATA"
            case `break` = "BREAK"
        }
        
        enum CodingKeys: String, CodingKey {
            case type
            case text
            case data
            case playServiceId
            case token
            case postDelayInMilliseconds
            case muteDelayInMilliseconds
            case actionTimeoutInMilliseconds
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            type = try container.decode(ActionType.self, forKey: .type)
            text = try? container.decode(String.self, forKey: .text)
            data = try? container.decode([String: AnyHashable].self, forKey: .data)
            playServiceId = try? container.decode(String.self, forKey: .playServiceId)
            token = try container.decode(String.self, forKey: .token)
            postDelayInMilliseconds = try? container.decode(Int.self, forKey: .postDelayInMilliseconds)
            muteDelayInMilliseconds = try? container.decode(Int.self, forKey: .muteDelayInMilliseconds)
            actionTimeoutInMilliseconds = try? container.decode(Int.self, forKey: .actionTimeoutInMilliseconds)
        }
    }
    
    enum RoutineType: String, Decodable {
        case voice = "VOICE"
        case schedule = "SCHEDULE"
        case alarmOff = "ALARM_OFF"
        case appStart = "APP_START"
    }
    
    enum RoutineListType: String, Decodable {
        case user = "USER"
        case preset = "PRESET"
        case recommend = "RECOMMEND"
    }
}

extension RoutineItem.Payload.Action {
    var postDelay: TimeIntervallic? {
        guard let postDelayInMilliseconds = postDelayInMilliseconds else { return nil }

        return NuguTimeInterval(milliseconds: postDelayInMilliseconds)
    }
    
    var muteDelay: TimeIntervallic? {
        guard let muteDelayInMilliseconds = muteDelayInMilliseconds else { return nil }
        
        return NuguTimeInterval(milliseconds: muteDelayInMilliseconds)
    }
}
