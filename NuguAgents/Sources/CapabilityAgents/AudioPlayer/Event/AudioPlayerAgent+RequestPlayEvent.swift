//
//  AudioPlayerAgent+RequestPlayEvent.swift
//  NuguAgents
//
//  Created by jin kim on 2020/03/23.
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
    struct RequestPlayEvent {
        let typeInfo: TypeInfo
        let referrerDialogRequestId: String?
        
        enum TypeInfo {
            case requestPlayCommandIssued(payload: [String: AnyHashable])
            case requestCommandFailed(state: AudioPlayerState, directiveType: String)
        }
    }
}

// MARK: - Eventable

extension AudioPlayerAgent.RequestPlayEvent: Eventable {
    var payload: [String: AnyHashable] {
        switch typeInfo {
        case .requestPlayCommandIssued(let payload):
            return payload
        case .requestCommandFailed(let state, let directiveType):
            return [
                "error": [
                    "type": "INVALID_COMMAND",
                    "message": "\(state.playerActivity) 상태에서는 \(directiveType) 를 처리할 수 없음"
                ]
            ]
        }
    }
    
    var name: String {
        switch typeInfo {
        case .requestPlayCommandIssued:
            return "RequestPlayCommandIssued"
        case .requestCommandFailed:
            return "RequestCommandFailed"
        }
    }
}
