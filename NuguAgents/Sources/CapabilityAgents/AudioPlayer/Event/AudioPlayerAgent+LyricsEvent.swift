//
//  AudioPlayerAgent+LyricsEvent.swift
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
    struct LyricsEvent {
        let typeInfo: TypeInfo
        let playServiceId: String
        let referrerDialogRequestId: String?
        
        enum TypeInfo {
            case showLyricsSucceeded
            case showLyricsFailed
            case hideLyricsSucceeded
            case hideLyricsFailed
            case controlLyricsPageSucceeded(direction: AudioPlayerDisplayControlPayload.Direction)
            case controlLyricsPageFailed(direction: AudioPlayerDisplayControlPayload.Direction)
        }
    }
}

// MARK: - Eventable

extension AudioPlayerAgent.LyricsEvent: Eventable {
    var payload: [String: AnyHashable] {
        var eventPayload: [String: AnyHashable] = [
            "playServiceId": playServiceId
        ]
        switch typeInfo {
        case .controlLyricsPageSucceeded(let direction):
            eventPayload["direction"] = direction.rawValue
        case .controlLyricsPageFailed(let direction):
            eventPayload["direction"] = direction.rawValue
        default:
            break
        }
        return eventPayload
    }
    
    var name: String {
        switch typeInfo {
        case .showLyricsSucceeded:
            return "ShowLyricsSucceeded"
        case .showLyricsFailed:
            return "ShowLyricsFailed"
        case .hideLyricsSucceeded:
            return "HideLyricsSucceeded"
        case .hideLyricsFailed:
            return "HideLyricsFailed"
        case .controlLyricsPageSucceeded:
            return "ControlLyricsPageSucceeded"
        case .controlLyricsPageFailed:
            return "ControlLyricsPageFailed"
        }
    }
}
