//
//  TextAgent+Event.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 17/06/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
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

extension TextAgent {
    struct Event {
        let typeInfo: TypeInfo
        let referrerDialogRequestId: String?
        
        enum TypeInfo {
            case textInput(text: String, token: String?, attributes: [String: AnyHashable]?)
            case textSourceFailed(token: String, playServiceId: String?, errorCode: String)
            case textRedirectFailed(token: String, playServiceId: String, errorCode: String, interactionControl: InteractionControl?)
        }
    }
}

// MARK: - Eventable

extension TextAgent.Event: Eventable {
    var payload: [String: AnyHashable] {
        var payload: [String: AnyHashable?]
        switch typeInfo {
        case .textInput(let text, let token, let attributes):
            payload = [
                "text": text,
                "token": token
            ].merged(with: attributes ?? [:])
            
        case .textSourceFailed(let token, let playServiceId, let errorCode):
            payload = [
                "token": token,
                "playServiceId": playServiceId,
                "errorCode": errorCode
            ]
        case .textRedirectFailed(let token, let playServiceId, let errorCode, let interactionControl):
            payload = [
                "token": token,
                "playServiceId": playServiceId,
                "errorCode": errorCode
            ]
            
            if let interactionControl = interactionControl,
               let interactionControlData = try? JSONEncoder().encode(interactionControl),
               let interactionControlDictionary = try? JSONSerialization.jsonObject(with: interactionControlData, options: []) as? [String: AnyHashable] {
                payload["interactionControl"] = interactionControlDictionary
            }
        }
        
        return payload.compactMapValues { $0 }
    }
    
    var name: String {
        switch typeInfo {
        case .textInput: return "TextInput"
        case .textSourceFailed: return "TextSourceFailed"
        case .textRedirectFailed: return "TextRedirectFailed"
        }
    }
}
