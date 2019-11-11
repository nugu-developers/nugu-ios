//
//  ASRExpectSpeech.swift
//  NuguInterface
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

public struct ASRExpectSpeech {
    public let timeoutInMilliseconds: Int?
    public let playServiceId: String?
    public let sessionId: String
    public let property: String?
    public let domainTypes: [String?]?
}

// MARK: - ASRExpectSpeech: Decodable

extension ASRExpectSpeech: Decodable {
    enum CodingKeys: String, CodingKey {
        case timeoutInMilliseconds
        case playServiceId
        case sessionId
        case property
        case domainTypes
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timeoutInMilliseconds = try? container.decode(Int.self, forKey: .timeoutInMilliseconds)
        playServiceId = try? container.decode(String.self, forKey: .playServiceId)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        property = try? container.decode(String.self, forKey: .property)
        domainTypes = try? container.decode([String?].self, forKey: .domainTypes)
    }
}

// MARK: - Equatable

extension ASRExpectSpeech: Equatable {}
