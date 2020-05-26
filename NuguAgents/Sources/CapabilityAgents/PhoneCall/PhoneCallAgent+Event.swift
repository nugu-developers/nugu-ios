//
//  PhoneCallAgent+Event.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/04/29.
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

extension PhoneCallAgent {
    public struct Event {
        let playServiceId: String
        let typeInfo: TypeInfo
        
        public enum TypeInfo {
            case candidatesListed(intent: String, callType: String, candidates: [PhoneCallPerson]?)
            case callArrived(callerName: String)
            case callEnded
            case callEstablished
            case makeCallFailed(errorCode: String, callType: String)
        }
    }
}

extension PhoneCallAgent.Event: Eventable {
    public var payload: [String : AnyHashable] {
        var payload: [String: AnyHashable] = [
            "playServiceId": playServiceId
        ]
        
        switch typeInfo {
        case .candidatesListed(let intent, let callType, let candidates):
            payload["intent"] = intent
            payload["callType"] = callType
            // TODO: - Encoding
//            payload["candidates"] = candidates
        case .callArrived(let callerName):
            payload["callerName"] = callerName
        case .callEnded:
            break
        case .callEstablished:
            break
        case .makeCallFailed(let errorCode, let callType):
            payload["errorCode"] = errorCode
            payload["callType"] = callType
        }
        
        return payload
    }
    
    public var name: String {
        switch typeInfo {
        case .candidatesListed:
            return "CandidatesListed"
        case .callArrived:
            return "CallArrived"
        case .callEnded:
            return "CallEnded"
        case .callEstablished:
            return "CallEstablished"
        case .makeCallFailed:
            return "MakeCallFailed"
        }
    }
}
