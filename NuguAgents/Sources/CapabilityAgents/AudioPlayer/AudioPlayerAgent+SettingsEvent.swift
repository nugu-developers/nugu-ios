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

import NuguCore

// MARK: - CapabilityEventAgentable

extension AudioPlayerAgent {
    public struct SettingsEvent {
        let playServiceId: String
        let typeInfo: TypeInfo
        
        public enum TypeInfo {
            case favoriteCommandIssued(isOn: Bool)
            case repeatCommandIssued(mode: AudioPlayerDisplayRepeat)
            case shuffleCommandIssued(isOn: Bool)
        }
    }
}

// MARK: - Eventable

extension AudioPlayerAgent.SettingsEvent: Eventable {
    public var payload: [String: Any] {
        var eventPayload: [String: Any] = [
            "playServiceId": playServiceId
        ]
        switch typeInfo {
        case .favoriteCommandIssued(let isOn):
            eventPayload["favorite"] = isOn
        case .repeatCommandIssued(let mode):
            eventPayload["repeat"] = mode
        case .shuffleCommandIssued(let isOn):
            eventPayload["shuffle"] = isOn
        }
        return eventPayload
    }
    
    public var name: String {
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
