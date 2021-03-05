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

// MARK: - Event

extension ASRAgent {
    struct Event {
        let typeInfo: TypeInfo
        let dialogAttributes: [String: AnyHashable]?
        let referrerDialogRequestId: String?
        
        enum TypeInfo {
            case recognize(initiator: ASRInitiator, options: ASROptions)
            case responseTimeout
            case listenTimeout
            case stopRecognize
            case listenFailed
        }
    }
    
    struct Attachment {
        let typeInfo: TypeInfo
        
        enum TypeInfo {
            case recognize
        }
    }
}

// MARK: - Eventable

extension ASRAgent.Event: Eventable {
    var payload: [String: AnyHashable] {
        var payload: [String: AnyHashable?]
        switch typeInfo {
        case .recognize(let initiator, let options):
            payload = [
                "codec": "SPEEX",
                "language": "KOR",
                "endpointing": options.endPointing.value,
                "encoding": options.encoding.value,
                "playServiceId": dialogAttributes?["playServiceId"],
                "domainTypes": dialogAttributes?["domainTypes"],
                "asrContext": dialogAttributes?["asrContext"],
                "timeout": [
                    "listen": options.timeout.truncatedMilliSeconds,
                    "maxSpeech": options.maxDuration.truncatedMilliSeconds,
                    "response": 10000
                ]
            ]
            
            if case let .wakeUpWord(keyword, _, start, end, detection) = initiator {
                var wakeup: [String: AnyHashable?] = ["word": keyword]
                if options.endPointing == .server {
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
                    wakeup["boundary"] = boundary
                }
                payload["wakeup"] = wakeup.compactMapValues { $0 }
            }
        case .listenTimeout,
             .stopRecognize,
             .listenFailed:
            payload = ["playServiceId": dialogAttributes?["playServiceId"]]
        default:
            payload = [:]
        }
        
        return payload.compactMapValues { $0 }
    }
    
    var name: String {
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

// MARK: - Attachable

extension ASRAgent.Attachment: Attachable {
    var name: String {
        switch typeInfo {
        case .recognize: return "Recognize"
        }
    }
    
    var type: String {
        switch typeInfo {
        case .recognize: return "audio/speex"
        }
    }
}
