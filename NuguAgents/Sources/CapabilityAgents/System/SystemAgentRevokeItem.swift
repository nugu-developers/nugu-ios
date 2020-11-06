//
//  SystemAgentRevokeItem.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/05/20.
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

struct SystemAgentRevokeItem {
    let reason: SystemAgentRevokeReason
}

// MARK: - SystemAgentRevokeItem + Codable

extension SystemAgentRevokeItem: Codable {
    enum CodingKeys: String, CodingKey {
        case reason
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        reason = (try? container.decode(SystemAgentRevokeReason.self, forKey: .reason)) ?? .unknown
    }
}
