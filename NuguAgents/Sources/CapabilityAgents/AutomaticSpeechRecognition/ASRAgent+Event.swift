//
//  ASRAgent+Event.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 11/06/2019.
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

import NuguCore

// MARK: - CapabilityEventAgentable

extension ASRAgent {
    public struct Event {
        let typeInfo: TypeInfo
        let expectSpeech: ASRExpectSpeech?
        
        public enum TypeInfo {
            case recognize(wakeUpInfo: WakeUpInfo?, encoding: ASREncoding)
            case responseTimeout
            case listenTimeout
            case stopRecognize
            case listenFailed
        }
        
        public struct WakeUpInfo {
            public let start: Int
            public let end: Int
            public let detection: Int
        }
    }
}

// MARK: - Eventable

extension ASRAgent.Event: Eventable {
    public var payload: [String: Any] {
        var payload: [String: Any?]
        switch typeInfo {
        case .recognize(let wakeUpInfo, let encoding):
            payload = [
                "codec": "SPEEX",
                "language": "KOR",
                "endpointing": "CLIENT",
                "encoding": encoding.rawValue,
                "sessionId": expectSpeech?.sessionId,
                "playServiceId": expectSpeech?.playServiceId,
                "property": expectSpeech?.property,
                "domainTypes": expectSpeech?.domainTypes
            ]
            if let wakeUpInfo = wakeUpInfo {
                payload["wakeUpBoundary"] = [
                    "detection": wakeUpInfo.detection,
                    "end": wakeUpInfo.end,
                    "start": wakeUpInfo.start
                ]
            }
        case .listenTimeout,
             .stopRecognize,
             .listenFailed:
            payload = ["playServiceId": expectSpeech?.playServiceId]
        default:
            payload = [:]
        }
        
        return payload.compactMapValues { $0 }
    }
    
    public var name: String {
        switch typeInfo {
        case .recognize:
            return "Recognize"
        case .responseTimeout:
            return "ResponseTimeout"
        case .listenTimeout:
            return "ListenTimeout"
        case .stopRecognize:
            return "StopRecognize"
        case .listenFailed:
            return "ListenFailed"
        }
    }
}

// MARK: - Equatable

extension ASRAgent.Event.TypeInfo: Equatable {}
extension ASRAgent.Event.WakeUpInfo: Equatable {}
extension ASRAgent.Event: Equatable {}
