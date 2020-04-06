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
            case recognize(options: ASROptions)
            case responseTimeout
            case listenTimeout
            case stopRecognize
            case listenFailed
        }
    }
}

// MARK: - Eventable

extension ASRAgent.Event: Eventable {
    public var payload: [String: AnyHashable] {
        var payload: [String: AnyHashable?]
        switch typeInfo {
        case .recognize(let options):
            payload = [
                "codec": "SPEEX",
                "language": "KOR",
                "endpointing": options.endPointing.value,
                "encoding": options.encoding.value,
                "sessionId": expectSpeech?.sessionId,
                "playServiceId": expectSpeech?.playServiceId,
                "domainTypes": expectSpeech?.domainTypes,
                "asrContext": expectSpeech?.asrContext,
                "timeout": [
                    "listen": options.timeout * 1000,
                    "maxSpeech": options.maxDuration * 1000,
                    "response": 10000
                ]
            ]

            if options.endPointing == .server,
                case let .wakeUpKeyword(keyword, _, start, end, detection) = options.initiator {
                // TODO: Tyche 라이브러리 업데이트 후 수정 필요.
                /**
                 KeywordDetector use 16k mono (bit depth: 16).
                 so, You can calculate sample count by (dataCount / 2)
                 */
                let boundary: [String: AnyHashable] = [
                    "start": start / 2,
                    "end": end / 2,
                    "detection": detection / 2,
                    "metric": "sample"
                ]
                let wakeup: [String: AnyHashable] = [
                    "word": keyword,
                    "boundary": boundary
                ]
                payload["wakeup"] = wakeup
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
extension ASRAgent.Event: Equatable {}
