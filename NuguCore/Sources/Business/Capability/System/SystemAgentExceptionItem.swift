//
//  SystemAgentExceptionItem.swift
//  NuguCore
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

import NuguInterface

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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let publicCode = try? container.decode(SystemAgentExceptionCode.Extra.self, forKey: .code) {
            code = .extra(code: publicCode)
        } else {
            code = .inside(code: try container.decode(SystemAgentExceptionCode.Inside.self, forKey: .code))
        }
        description = try container.decode(String.self, forKey: .description)
    }
}
