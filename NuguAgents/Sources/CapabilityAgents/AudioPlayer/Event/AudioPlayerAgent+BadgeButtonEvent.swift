//
//  AudioPlayerAgent+BadgeButtonEvent.swift
//  NuguAgents
//
//  Copyright © 2024 SK Telecom Co., Ltd. All rights reserved.
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

// MARK: - Event

extension AudioPlayerAgent {
    struct BadgeButtonEvent {
        let typeInfo: TypeInfo
        let playServiceId: String?
        
        enum TypeInfo {
            case badgeButtonSelected(token: String, postback: [String: AnyHashable])
        }
    }
}

// MARK: - Eventable

extension AudioPlayerAgent.BadgeButtonEvent: Eventable {
    var payload: [String: AnyHashable] {
        var eventPayload: [String: AnyHashable] = [
            "playServiceId": playServiceId
        ]
        
        switch typeInfo {
        case .badgeButtonSelected(token: let playlistItemToken, postback: let postback):
            eventPayload["token"] = playlistItemToken
            eventPayload["postback"] = postback
            
            if playServiceId == nil {
                eventPayload["playServiceId"] = postback["playServiceId"]
            }
        }
        
        return eventPayload
    }
    
    var name: String {
        switch typeInfo {
        case .badgeButtonSelected:
            return "ElementSelected"
        }
    }
}
