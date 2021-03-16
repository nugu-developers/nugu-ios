//
//  AlertsAgentDirectivePayload.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/03/05.
//  Copyright (c) 2021 SK Telecom Co., Ltd. All rights reserved.
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

import Foundation

/// <#Description#>
public struct AlertsAgentDirectivePayload {
    
    /// <#Description#>
    public struct SetAlert: Codable {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
        /// <#Description#>
        public let alertType: String
        /// <#Description#>
        public let scheduledTime: String
        /// <#Description#>
        public let activation: Bool
        /// <#Description#>
        public let minDurationInSec: Int?
        /// <#Description#>
        public let `repeat`: AlertsRepeat?
        /// <#Description#>
        public let alarmResourceType: String?
        /// <#Description#>
        public let assetRequiredInMilliseconds: Int?
        /// <#Description#>
        public let assets: [AlertsAsset]
    }
    
    /// <#Description#>
    public struct DeleteAlerts: Codable {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let tokens: [String]
    }
    
    /// <#Description#>
    public struct DeliveryAlertAsset: Codable {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
        /// <#Description#>
        public let assetDetails: [String: AnyHashable]?
        
        enum CodingKeys: String, CodingKey {
            case playServiceId
            case token
            case assetDetails
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            playServiceId = try container.decode(String.self, forKey: .playServiceId)
            token = try container.decode(String.self, forKey: .token)
            assetDetails = try container.decodeIfPresent([String: AnyHashable].self, forKey: .assetDetails)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(playServiceId, forKey: .playServiceId)
            try container.encode(token, forKey: .token)
            try container.encodeIfPresent(assetDetails, forKey: .assetDetails)
        }
    }
    
    /// <#Description#>
    public struct SetSnooze: Codable {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
        /// <#Description#>
        public let durationInSec: Int
    }
}
