//
//  AlertsAgentDelegate.swift
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

import NuguCore

public protocol AlertsAgentDelegate: AnyObject {
    
    /// Provide a context of `AlertsAgent`.
    ///
    /// This function should return as soon as possible to reduce request delay.
    /// - Returns: The context for `AlertsAgent`
    func alertsAgentRequestContext() -> AlertsAgentContext
    
    /// <#Description#>
    /// - Parameters:
    ///   - item: <#payload description#>
    ///   - header: <#header description#>
    func alertsAgentDidReceiveSetAlert(item: AlertsAgentDirectivePayload.SetAlert, header: Downstream.Header) -> Bool
    
    /// <#Description#>
    /// - Parameters:
    ///   - item: <#item description#>
    ///   - header: <#header description#>
    func alertsAgentDidReceiveDeleteAlerts(item: AlertsAgentDirectivePayload.DeleteAlerts, header: Downstream.Header) -> Bool
    
    /// <#Description#>
    /// - Parameters:
    ///   - item: <#item description#>
    ///   - header: <#header description#>
    /// - Returns:If `false`, NUGU SDK handle it.
    func alertsAgentDidReceiveDeliveryAlertAsset(item: AlertsAgentDirectivePayload.DeliveryAlertAsset, header: Downstream.Header) -> Bool
    
    /// <#Description#>
    /// - Parameters:
    ///   - item: <#item description#>
    ///   - header: <#header description#>
    func alertsAgentDidReceiveSetSnooze(item: AlertsAgentDirectivePayload.SetSnooze, header: Downstream.Header) -> Bool
}
