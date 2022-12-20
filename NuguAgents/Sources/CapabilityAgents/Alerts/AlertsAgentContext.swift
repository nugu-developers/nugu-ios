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

public struct AlertsAgentContext: Codable {
    public struct Alert: Codable {
        public let playServiceId: String
        public let token: String
        public let alertType: String
        public let scheduledTime: String
        public let activation: Bool
        public let minDurationInSec: Int?
        public let `repeat`: AlertsRepeat?
        public let alarmResourceType: String?
        public let assetRequiredInMilliseconds: Int?
        public let alertConfirmedInMilliseconds: Int?
        public let creationTime: Int?
        public let modificationTime: Int?
        public let name: String?
        public let assets: [AlertsAsset]
        
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
            alertConfirmedInMilliseconds: Int?,
            creationTime: Int?,
            modificationTime: Int?,
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
            self.alertConfirmedInMilliseconds = alertConfirmedInMilliseconds
            self.creationTime = creationTime
            self.modificationTime = modificationTime
            self.name = name
            self.assets = assets
        }
    }
    
    public let maxAlertCount: Int
    public let maxAlarmCount: Int
    public let supportedTypes: [String]
    public let supportedAlarmResourceTypes: [String]
    public let internalAlarms: [[String: String]]
    public let allAlerts: [Alert]
    public let activeAlarmToken: String?
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
