//
//  Policy.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 19/07/2019.
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

struct Policy: Decodable {
    let serverPolicies: [ServerPolicy]
    let healthCheckPolicy: HealthCheckPolicy
    
    struct ServerPolicy: Decodable {
        let serverPolicyProtocol: String
        let hostname: String
        let address: String
        let port: Int
        let retryCountLimit: Int
        let connectionTimeout: Int
        let charge: String
        
        enum CodingKeys: String, CodingKey {
            case serverPolicyProtocol = "protocol"
            case hostname
            case address
            case port
            case retryCountLimit
            case connectionTimeout, charge
        }
    }
    
    struct HealthCheckPolicy: Decodable {
        let ttl: Int
        let ttlMax: Int
        let beta: Int
        let retryCountLimit: Int
        let retryDelay: Int
        let healthCheckTimeout: Int
        let accumulationTime: Int
    }
}
