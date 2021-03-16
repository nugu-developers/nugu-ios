//
//  AlertsAgentContext.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/02/26.
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
public struct AlertsAgentContext: Codable {
    
    /// <#Description#>
    public struct Alert: Codable {
        /// <#Description#>
        public struct Repeat: Codable {
            /// <#Description#>
            public let type: String
            /// <#Description#>
            public let daysOfWeek: [String]?
        }
        
        /// <#Description#>
        public struct Asset: Codable {
            /// <#Description#>
            public let type: String
            /// <#Description#>
            public let resource: String? // TODO: - Dynamic object
        }
        
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
        public let `repeat`: Repeat?
        /// <#Description#>
        public let alarmResourceType: String?
        /// <#Description#>
        public let assetRequiredInMilliseconds: Int?
        /// <#Description#>
        public let assets: [Asset]
    }
    
    /// <#Description#>
    public let maxAlertCount: Int
    /// <#Description#>
    public let maxAlarmCount: Int
    /// <#Description#>
    public let supportedTypes: [String]
    /// <#Description#>
    public let supportedAlarmResourceTypes: [String]
    /// <#Description#>
    public let internalAlarms: [[String: String]]
    /// <#Description#>
    public let allAlerts: [Alert]
    /// <#Description#>
    public let activeAlarmToken: String?
    
}
