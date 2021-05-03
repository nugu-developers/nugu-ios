//
//  ASRExpectSpeech.swift
//  NuguAgents
//
//  Created by MinChul Lee on 13/05/2019.
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
import NuguUtils

/// The information about multiturn.
///
/// NUGU ask you to get more information to know about you requested.
struct ASRExpectSpeech {
    let messageId: String
    let dialogRequestId: String
    let payload: Payload
    
    struct Payload {
        let playServiceId: String?
        let domainTypes: [AnyHashable]?
        let asrContext: [String: AnyHashable]?
        let epd: EPD?
        let listenTimeoutFailBeep: Bool?

        struct EPD: Decodable {
            let timeoutMilliseconds: Int?
            let silenceIntervalInMilliseconds: Int?
            let maxSpeechDurationMilliseconds: Int?
        }
    }
}

// MARK: - ASRExpectSpeech.Payload: Decodable

extension ASRExpectSpeech.Payload: Decodable {
    enum CodingKeys: String, CodingKey {
        case playServiceId
        case domainTypes
        case asrContext
        case epd
        case listenTimeoutFailBeep
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playServiceId = try? container.decode(String.self, forKey: .playServiceId)
        domainTypes = try? container.decode([AnyHashable].self, forKey: .domainTypes)
        asrContext = try? container.decodeIfPresent([String: AnyHashable].self, forKey: .asrContext)
        epd = try? container.decode(EPD.self, forKey: .epd)
        listenTimeoutFailBeep = try? container.decode(Bool.self, forKey: .listenTimeoutFailBeep)
    }
}

// MARK: - ASRExpectSpeech.Payload.EPD+TimeIntervallic

extension ASRExpectSpeech.Payload.EPD {
    var timeout: TimeIntervallic? {
        guard let timeoutMilliseconds = timeoutMilliseconds else { return nil }
        
        return NuguTimeInterval(milliseconds: timeoutMilliseconds)
    }
    var maxDuration: TimeIntervallic? {
        guard let maxSpeechDurationMilliseconds = maxSpeechDurationMilliseconds else { return nil }
        
        return NuguTimeInterval(milliseconds: maxSpeechDurationMilliseconds)
    }
    var pauseLength: TimeIntervallic? {
        guard let silenceIntervalInMilliseconds = silenceIntervalInMilliseconds else { return nil }
        
        return NuguTimeInterval(milliseconds: silenceIntervalInMilliseconds)
    }
}
