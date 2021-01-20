//
//  DirectiveHandleResult.swift
//  NuguCore
//
//  Created by MinChul Lee on 2020/07/08.
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

import NuguUtils

/// <#Description#>
public enum DirectiveHandleResult {
    case failed(_ description: String)
    case canceled
    case stopped(directiveCancelPolicy: DirectiveCancelPolicy)
    case finished
}

extension DirectiveHandleResult: Codable {
    var index: Int {
        switch self {
        case .failed:
            return 0
        case .canceled:
            return 1
        case .stopped:
            return 2
        case .finished:
            return 3
        }
    }
    
    enum CodingKeys: CodingKey {
        case index
        case associatedValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let index = try container.decode(Int.self, forKey: .index)
        switch index {
        case 0:
            let description = try container.decode(String.self, forKey: .associatedValue)
            self = .failed(description)
        case 1:
            self = .canceled
        case 2:
            let policy = try container.decode(DirectiveCancelPolicy.self, forKey: .associatedValue)
            self = .stopped(directiveCancelPolicy: policy)
        case 3:
            self = .finished
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unmatched case"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.index, forKey: .index)
        
        switch self {
        case let .failed(description):
            try container.encode(description, forKey: .associatedValue)
        case let .stopped(directiveCancelPolicy):
            try container.encode(directiveCancelPolicy, forKey: .associatedValue)
        default:
            break
        }
    }
}
