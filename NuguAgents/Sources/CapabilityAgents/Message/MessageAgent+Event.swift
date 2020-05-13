//
//  MessageAgent+Event.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/05/06.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

extension MessageAgent {
    public struct Event {
        let playServiceId: String
        let typeInfo: TypeInfo
        
        public enum TypeInfo {
            case candidatesListed(candidates: [MessageContact]?)
            case sendMessageSucceeded(recipient: [MessageContact])
            case sendMessageFailed(recipient: [MessageContact], errorCode: String)
            case getMessageSucceeded(candidates: [MessageContact]?)
            case getMessageFailed(errorCode: String)
        }
    }
}

// MARK: - Eventable

extension MessageAgent.Event: Eventable {
    public var payload: [String : AnyHashable] {
        var payload: [String: AnyHashable] = [
            "playServiceId": playServiceId
        ]
        
        // TODO: - Encoding
        
        switch typeInfo {
        case .candidatesListed(let candidates):
            break
        case .sendMessageSucceeded(let recipient):
            break
        case .sendMessageFailed(let recipient, let errorCode):
            break
        case .getMessageSucceeded(let candidates):
            break
        case .getMessageFailed(let errorCode):
            payload["errorCode"] = errorCode
        }
        
        return payload
    }
    
    public var name: String {
        switch typeInfo {
        case .candidatesListed:
            return "CandidatesListed"
        case .sendMessageSucceeded:
            return "SendMessageSucceeded"
        case .sendMessageFailed:
            return "SendMessageFailed"
        case .getMessageSucceeded:
            return "GetMessageSucceeded"
        case .getMessageFailed:
            return "GetMessageFailed"
        }
    }
}
