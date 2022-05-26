//
//  MessengerAgent+Event.swift
//  NuguMessengerAgent
//
//  Created by yonghoonKwon on 2021/04/13.
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
//

import Foundation

import NuguCore

extension MessengerAgent {
    struct Event {
        let typeInfo: TypeInfo
        let referrerDialogRequestId: String?
        
        enum TypeInfo {
            case create(playServiceId: String)
            case sync(item: MessengerAgentEventPayload.Sync)
            case enter(item: MessengerAgentEventPayload.Enter)
            case message(item: MessengerAgentEventPayload.Message)
            case exit(roomId: String)
            case read(roomId: String, readMessageId: String)
            case reaction(item: MessengerAgentEventPayload.Reaction)
            case directiveDelivered(roomId: String)
        }
    }
}

// MARK: - MessengerAgent.Event + Eventable

extension MessengerAgent.Event: Eventable {
    var payload: [String: AnyHashable] {
        switch typeInfo {
        case .create(let playServiceId):
            return ["playServiceId": playServiceId]
        case .sync(let item):
            return [
                "roomId": item.roomId,
                "baseTimestamp": item.baseTimestamp,
                "direction": item.direction,
                "num": item.num
            ]
        case .enter(let item):
            return [
                "roomId": item.roomId,
                "enterType": item.enterType.rawValue
            ]
        case .message(let item):
            var payload: [String: AnyHashable] = [
                "roomId": item.roomId,
                "id": item.id,
                "timestamp": item.timestamp,
                "format": item.format,
                "text": item.text
            ]
            
            if let postback = item.postback,
               let postbackData = try? JSONEncoder().encode(postback),
               let postbackDic = try? JSONSerialization.jsonObject(with: postbackData, options: []) as? [String: AnyHashable] {
                payload["postback"] = postbackDic
            }
            
            if let templateDic = item.template {
                payload["template"] = templateDic
            }
            
            return payload
        case .exit(let roomId):
            return ["roomId": roomId]
        case .read(let roomId, let readMessageId):
            return [
                "roomId": roomId,
                "readMessageId": readMessageId
            ]
        case .reaction(let item):
            return [
                "roomId": item.roomId,
                "action": item.action,
                "actionDurationInMilliseconds": item.actionDurationInMilliseconds
            ]
        case .directiveDelivered(let roomId):
            return ["roomId": roomId]
        }
    }
    
    var name: String {
        switch typeInfo {
        case .create: return "Create"
        case .sync: return "Sync"
        case .enter: return "Enter"
        case .message: return "Message"
        case .exit: return "Exit"
        case .read: return "Read"
        case .reaction: return "Reaction"
        case .directiveDelivered: return "DirectiveDelivered"
        }
    }
}
