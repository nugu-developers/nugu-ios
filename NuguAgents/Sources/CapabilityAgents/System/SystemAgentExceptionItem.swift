//
//  SystemAgentExceptionItem.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 28/06/2019.
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

struct SystemAgentExceptionItem {
    let code: SystemAgentExceptionCode
    let description: String
}

// MARK: - SystemAgentExceptionItem + Decodable

extension SystemAgentExceptionItem: Decodable {
    enum CodingKeys: String, CodingKey {
        case code
        case description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let failCode = try? container.decode(SystemAgentExceptionCode.Fail.self, forKey: .code) {
            code = .fail(code: failCode)
        } else {
            code = .warning(code: try container.decode(SystemAgentExceptionCode.Warning.self, forKey: .code))
        }
        description = try container.decode(String.self, forKey: .description)
    }
}
