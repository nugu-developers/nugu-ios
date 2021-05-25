//
//  AlertsAgent+Event.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/02/26.
//  Copyright (c) 2021 SK Telecom Co., Ltd. All rights reserved.
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

import Foundation

extension AlertsAgent {
    struct Event {
        let typeInfo: TypeInfo
        let playServiceId: String
        let referrerDialogRequestId: String?
        
        enum TypeInfo {
            case setAlertSucceeded(token: String)
            case setAlertFailed(token: String)
            case deleteAlertsSucceeded(tokens: [String])
            case deleteAlertsFailed(tokens: [String])
            case setSnoozeSucceeded(token: String)
            case setSnoozeFailed(token: String)
            // case alertStarted // Cannot use
            // case alertFailed // Cannot use
            // case alertIgnored // Cannot use
            // case alertStopped // Cannot use
            // case alertEnteredForeground // Cannot use
            // case alertEnteredBackground // Cannot use
            case alertAssetRequired(token: String) // 필요할지 검토 필요해보임
        }
    }
}

// MARK: - Eventable

extension AlertsAgent.Event: Eventable {
    var payload: [String: AnyHashable] {
        var payload: [String: AnyHashable] = [
            "playServiceId": playServiceId
        ]
        
        switch typeInfo {
        case .setAlertSucceeded(let token):
            payload["token"] = token
        case .setAlertFailed(let token):
            payload["token"] = token
        case .deleteAlertsSucceeded(let tokens):
            payload["tokens"] = tokens
        case .deleteAlertsFailed(let tokens):
            payload["tokens"] = tokens
        case .setSnoozeSucceeded(let token):
            payload["token"] = token
        case .setSnoozeFailed(let token):
            payload["token"] = token
        case .alertAssetRequired(let token):
            payload["token"] = token
        }
        
        return payload
    }
    
    var name: String {
        switch typeInfo {
        case .setAlertSucceeded:
            return "SetAlertSucceeded"
        case .setAlertFailed:
            return "SetAlertFailed"
        case .deleteAlertsSucceeded:
            return "DeleteAlertsSucceeded"
        case .deleteAlertsFailed:
            return "DeleteAlertsFailed"
        case .setSnoozeSucceeded:
            return "SetSnoozeSucceeded"
        case .setSnoozeFailed:
            return "SetSnoozeFailed"
        case .alertAssetRequired:
            return "AlertAssetRequired"
        }
    }
}
