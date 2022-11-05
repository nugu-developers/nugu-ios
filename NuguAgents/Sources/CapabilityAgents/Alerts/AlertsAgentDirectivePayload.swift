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

import NuguCore

public enum AlertsAgentDirectivePayload {
    public struct SetAlert: Codable {
        public let playServiceId: String
        public let token: String
        public let alertType: String
        public let scheduledTime: String
        public let activation: Bool
        public let minDurationInSec: Int?
        public let `repeat`: AlertsRepeat?
        public let alarmResourceType: String?
        public let assetRequiredInMilliseconds: Int?
        public let creationTime: Int?
        public let alertConfirmedInMilliseconds: Int?
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
            repeat: AlertsRepeat?,
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
    
    public struct DeleteAlerts: Codable {
        public let playServiceId: String
        public let tokens: [String]
        
        public init(
            playServiceId: String,
            tokens: [String]
        ) {
            self.playServiceId = playServiceId
            self.tokens = tokens
        }
    }
    
    public struct DeliveryAlertAsset: Codable {
        public let playServiceId: String
        public let token: String
        private let assetDetails: [[String: AnyHashable]]?
        public let directives: [Downstream.Directive]?
        
        enum CodingKeys: String, CodingKey {
            case playServiceId
            case token
            case assetDetails
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            playServiceId = try container.decode(String.self, forKey: .playServiceId)
            token = try container.decode(String.self, forKey: .token)
            assetDetails = try container.decodeIfPresent([[String: AnyHashable]].self, forKey: .assetDetails)
            
            if let assets = assetDetails {
                var directiveStore = [Downstream.Directive]()
                assets
                    .compactMap(Downstream.Directive.init)
                    .forEach { directive in
                        directiveStore.append(directive)
                }
                directives = directiveStore
            } else {
                directives = nil
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(playServiceId, forKey: .playServiceId)
            try container.encode(token, forKey: .token)
            try container.encodeIfPresent(assetDetails, forKey: .assetDetails)
        }
    }
    
    public struct SetSnooze: Codable {
        public let playServiceId: String
        public let token: String
        public let durationInSec: Int
    }
    
    public struct SkipNextAlert: Codable {
        public let playServiceId: String
        public let token: String
        public let type: String
    }
}
