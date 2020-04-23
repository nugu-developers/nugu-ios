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

/// The information about multiturn.
///
/// NUGU ask you to get more information to know about you requested.
public struct ASRExpectSpeech {
    public let playServiceId: String?
    public let sessionId: String
    public let domainTypes: [AnyHashable]?
    public let asrContext: [String: AnyHashable]?
}

// MARK: - ASRExpectSpeech: Decodable

extension ASRExpectSpeech: Decodable {
    enum CodingKeys: String, CodingKey {
        case playServiceId
        case sessionId
        case domainTypes
        case asrContext
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playServiceId = try? container.decode(String.self, forKey: .playServiceId)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        domainTypes = try? container.decode([AnyHashable].self, forKey: .domainTypes)
        asrContext = try? container.decode([String: AnyHashable].self, forKey: .asrContext)
    }
}

// MARK: - Equatable

extension ASRExpectSpeech: Equatable {}
