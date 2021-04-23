//
//  Routine+Event.swift
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

// MARK: - CapabilityEventAgentable
extension RoutineAgent {
    struct Event {
        let typeInfo: TypeInfo
        let playServiceId: String?
        let referrerDialogRequestId: String?

        enum TypeInfo {
            case started
            case failed(errorCode: String)
            case finished
            case stopped
            case actionTriggered(data: [String: AnyHashable]?)
        }
    }
}

// MARK: - Eventable
extension RoutineAgent.Event: Eventable {
    var payload: [String: AnyHashable] {
        var payload: [String: AnyHashable] = [
            "playServiceId": playServiceId
        ]
        switch typeInfo {
        case .failed(let errorCode):
            payload["errorCode"] = errorCode
        case .actionTriggered(let data):
            payload["data"] = data
        default:
            break
        }
        return payload
    }

    var name: String {
        switch typeInfo {
        case .started:
            return "Started"
        case .failed:
            return "Failed"
        case .finished:
            return "Finished"
        case .stopped:
            return "Stopped"
        case .actionTriggered:
            return "ActionTriggered"
        }
    }
}
