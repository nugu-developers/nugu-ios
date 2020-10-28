//
//  AudioPlayerAgent+SettingsEvent.swift
//  NuguAgents
//
//  Created by jin kim on 2020/03/16.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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
    struct SettingsEvent {
        let typeInfo: TypeInfo
        let playServiceId: String
        let referrerDialogRequestId: String?
        
        enum TypeInfo {
            case favoriteCommandIssued(current: Bool)
            case repeatCommandIssued(currentMode: AudioPlayerDisplayRepeat)
            case shuffleCommandIssued(current: Bool)
        }
    }
}

// MARK: - Eventable

extension AudioPlayerAgent.SettingsEvent: Eventable {
    var payload: [String: AnyHashable] {
        var eventPayload: [String: AnyHashable] = [
            "playServiceId": playServiceId
        ]
        switch typeInfo {
        case .favoriteCommandIssued(let current):
            eventPayload["favorite"] = current
        case .repeatCommandIssued(let currentMode):
            eventPayload["repeat"] = currentMode.rawValue
        case .shuffleCommandIssued(let current):
            eventPayload["shuffle"] = current
        }
        return eventPayload
    }
    
    var name: String {
        switch typeInfo {
        case .favoriteCommandIssued:
            return "FavoriteCommandIssued"
        case .repeatCommandIssued:
            return "RepeatCommandIssued"
        case .shuffleCommandIssued:
            return "ShuffleCommandIssued"
        }
    }
}
