//
//  ExtensionAgent+Event.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 25/07/2019.
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

import NuguCore

// MARK: - CapabilityEventAgentable

extension ExtensionAgent {
    public struct Event {
        let playServiceId: String
        let typeInfo: TypeInfo
        
        public enum TypeInfo {
            case actionSucceeded
            case actionFailed
            case commandIssued(data: AnyHashable)
        }
    }
}

// MARK: - Eventable

extension ExtensionAgent.Event: Eventable {
    public var payload: [String: AnyHashable] {
        var payload: [String: AnyHashable] = [
            "playServiceId": playServiceId
        ]
        switch typeInfo {
        case .commandIssued(let data):
            payload["data"] = data
        default:
            break
        }
        return payload
    }
    
    public var name: String {
        switch typeInfo {
        case .actionSucceeded:
            return "ActionSucceeded"
        case .actionFailed:
            return "ActionFailed"
        case .commandIssued:
            return "CommandIssued"
        }
    }
}
