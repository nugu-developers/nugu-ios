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

public struct Policy: Decodable {
    public let serverPolicies: [ServerPolicy]
    public let healthCheckPolicy: HealthCheckPolicy
    
    public struct ServerPolicy: Decodable {
        public let serverPolicyProtocol: String
        public let hostname: String
        public let port: Int
        public let retryCountLimit: Int
        public let connectionTimeout: Int
        public let charge: String
        
        private enum CodingKeys: String, CodingKey {
            case serverPolicyProtocol = "protocol"
            case hostname
            case port
            case retryCountLimit
            case connectionTimeout, charge
        }
    }
    
    public struct HealthCheckPolicy: Decodable {
        public let ttl: Int
        public let ttlMax: Int
        public let beta: Int
        public let retryCountLimit: Int
        public let retryDelay: Int
        public let healthCheckTimeout: Int
        public let accumulationTime: Int
    }
}
