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
        
        enum TypeInfo {
            case textInput(text: String, token: String?, expectSpeech: ASRExpectSpeech?)
        }
    }
}

// MARK: - Eventable

extension TextAgent.Event: Eventable {
    var payload: [String: AnyHashable] {
        var payload: [String: AnyHashable?]
        switch typeInfo {
        case .textInput(let text, let token, let expectSpeech):
            payload = [
                "text": text,
                "token": token,
                "sessionId": expectSpeech?.sessionId,
                "playServiceId": expectSpeech?.playServiceId,
                "domainTypes": expectSpeech?.domainTypes,
                "asrContext": expectSpeech?.asrContext
            ]
        }
        
        return payload.compactMapValues { $0 }
    }
    
    var name: String {
        switch typeInfo {
        case .textInput:
            return "TextInput"
        }
    }
}
