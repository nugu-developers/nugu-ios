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
        public let name: String?
        /// <#Description#>
        public let assets: [AlertsAsset]
        
        /// <#Description#>
        /// - Parameters:
        ///   - playServiceId: <#playServiceId description#>
        ///   - token: <#token description#>
        ///   - alertType: <#alertType description#>
        ///   - scheduledTime: <#scheduledTime description#>
        ///   - activation: <#activation description#>
        ///   - minDurationInSec: <#minDurationInSec description#>
        ///   - repeat: <#repeat description#>
        ///   - alarmResourceType: <#alarmResourceType description#>
        ///   - assetRequiredInMilliseconds: <#assetRequiredInMilliseconds description#>
        ///   - name: <#name description#>
        ///   - assets: <#assets description#>
        public init(
            playServiceId: String,
            token: String,
            alertType: String,
            scheduledTime: String,
            activation: Bool,
            minDurationInSec: Int?,
            `repeat`: AlertsRepeat?,
            alarmResourceType: String?,
            assetRequiredInMilliseconds: Int?,
            name: String?,
            assets: [AlertsAsset]
        ) {
            self.playServiceId = playServiceId
            self.token = token
            self.alertType = alertType
            self.scheduledTime = scheduledTime
            self.activation = activation
            self.minDurationInSec = minDurationInSec
            self.repeat = `repeat`
            self.alarmResourceType = alarmResourceType
            self.assetRequiredInMilliseconds = assetRequiredInMilliseconds
            self.name = name
            self.assets = assets
        }
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
    
    /// <#Description#>
    /// - Parameters:
    ///   - maxAlertCount: <#maxAlertCount description#>
    ///   - maxAlarmCount: <#maxAlarmCount description#>
    ///   - supportedTypes: <#supportedType description#>
    ///   - supportedAlarmResourceTypes: <#supportedAlarmResourceTypes description#>
    ///   - internalAlarms: <#internalAlarms description#>
    ///   - allAlerts: <#allAlerts description#>
    ///   - activeAlarmToken: <#activeAlarmToken description#>
    public init(
        maxAlertCount: Int,
        maxAlarmCount: Int,
        supportedTypes: [String],
        supportedAlarmResourceTypes: [String],
        internalAlarms: [[String: String]],
        allAlerts: [Alert],
        activeAlarmToken: String?
    ) {
        self.maxAlertCount = maxAlertCount
        self.maxAlarmCount = maxAlarmCount
        self.supportedTypes = supportedTypes
        self.supportedAlarmResourceTypes = supportedAlarmResourceTypes
        self.internalAlarms = internalAlarms
        self.allAlerts = allAlerts
        self.activeAlarmToken = activeAlarmToken
    }
}
