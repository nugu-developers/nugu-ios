//
//  Image+Event.swift
//  NuguAgents
//
//  Created by jayceSub on 2023/05/10.
//  Copyright (c) 2023 SK Telecom Co., Ltd. All rights reserved.
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

// MARK: - CapabilityEventAgentable

extension ImageAgent {
    struct Event {
        let typeInfo: TypeInfo
        let referrerDialogRequestId: String?

        enum TypeInfo {
            case sendImage(roomId: String?, playServiceId: String?)
        }
    }
    
    struct Attachment {
        let typeInfo: TypeInfo
        
        enum TypeInfo {
            case sendImage
        }
    }
}

// MARK: - Eventable

extension ImageAgent.Event: Eventable {
    var payload: [String: AnyHashable] {
        var payload: [String: AnyHashable] = [:]
        switch typeInfo {
        case let .sendImage(roomId, playServiceId):
            payload["roomId"] = roomId
            payload["playServiceId"] = playServiceId
        default:
            break
        }
        return payload
    }

    var name: String {
        switch typeInfo {
        case .sendImage: return "SendImage"
        }
    }
}


// MARK: - Attachable

extension ImageAgent.Attachment: Attachable {
    var name: String {
        switch typeInfo {
        case .sendImage: return "SendImage"
        }
    }
    
    var type: String {
        switch typeInfo {
        case .sendImage: return "application/octet-stream"
        }
    }
}
