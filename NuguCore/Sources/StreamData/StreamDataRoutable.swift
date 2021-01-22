//
//  StreamDataRoutable.swift
//  NuguCore
//
//  Created by MinChul Lee on 11/22/2019.
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

import NuguUtils

/// Determine the destinations for receiving `Downstream` data and sending `Upstream` data.
public protocol StreamDataRoutable: UpstreamDataSendable, TypedNotifyable {
    /// Enable connection-oriented feature to receive server initiated directive.
    ///
    /// - Parameter completion: The completion handler. Pass `StreamDataState.error` when connection failed.
    func startReceiveServerInitiatedDirective(completion: ((StreamDataState) -> Void)?)
    
    /// Enable connection-oriented feature with specific policy.
    ///
    /// - Parameter serverPolicy: The policy for connecting to the server.
    func startReceiveServerInitiatedDirective(to serverPolicy: Policy.ServerPolicy)
    
    /// Refersh the policy for connecting to the server.
    func restartReceiveServerInitiatedDirective()
    
    /// Disable connection-oriented feature.
    func stopReceiveServerInitiatedDirective()
}
