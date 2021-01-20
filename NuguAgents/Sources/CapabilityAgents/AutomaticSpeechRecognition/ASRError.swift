//
//  ASRError.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2019/09/30.
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
public enum ASRError: CodableError {
    /// Recognize event 시작 후 10초(default) 동안 사용자가 발화하지 않음.
    case listeningTimeout
    /// 음성 인식 시작 실패
    case listenFailed
    /// 음성 인식 실패
    case recognizeFailed
    
    public var code: Int {
        switch self {
        case .listeningTimeout:
            return 0
        case .listenFailed:
            return 1
        case .recognizeFailed:
            return 2
        }
    }
    
    public var name: String {
        switch self {
        case .listeningTimeout:
            return "listeningTimeout"
        case .listenFailed:
            return "listenFailed"
        case .recognizeFailed:
            return "recognizeFailed"
        }
    }

    enum CodingKeys: CodingKey {
        case code
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let code = try container.decode(CodableError.Code.self, forKey: .code)
        switch code {
        case ASRError.listeningTimeout.code:
            self = .listeningTimeout
        case ASRError.listenFailed.code:
            self = .listenFailed
        case ASRError.recognizeFailed.code:
            self = .recognizeFailed
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unmatched case"))}
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.code, forKey: .code)
    }
}
