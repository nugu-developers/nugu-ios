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

/// The information about multiturn.
///
/// NUGU ask you to get more information to know about you requested.
public struct ASRExpectSpeech {
    public let timeoutInMilliseconds: Int?
    public let playServiceId: String?
    public let sessionId: String
    public let property: String?
    public let domainTypes: [String?]?
    public let asrContext: ASRContext?
    
    public struct ASRContext {
        public let task: String?
        public let sceneId: String?
        public let sceneText: [String?]?
    }
    
}

// MARK: - ASRExpectSpeech: Decodable

extension ASRExpectSpeech: Decodable {
    enum CodingKeys: String, CodingKey {
        case timeoutInMilliseconds
        case playServiceId
        case sessionId
        case property
        case domainTypes
        case asrContext
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timeoutInMilliseconds = try? container.decode(Int.self, forKey: .timeoutInMilliseconds)
        playServiceId = try? container.decode(String.self, forKey: .playServiceId)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        property = try? container.decode(String.self, forKey: .property)
        domainTypes = try? container.decode([String?].self, forKey: .domainTypes)
        asrContext = try? container.decode(ASRContext.self, forKey: .asrContext)
    }
}

// MARK: - ASRExpectSpeech.ASRContext: Decodable

extension ASRExpectSpeech.ASRContext: Decodable {
    enum CodingKeys: String, CodingKey {
        case task
        case sceneId
        case sceneText
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        task = try? container.decode(String.self, forKey: .task)
        sceneId = try? container.decode(String.self, forKey: .sceneId)
        sceneText = try? container.decode([String?].self, forKey: .sceneText)
    }
}

// MARK: - Equatable

extension ASRExpectSpeech: Equatable {}

extension ASRExpectSpeech.ASRContext: Equatable {}
