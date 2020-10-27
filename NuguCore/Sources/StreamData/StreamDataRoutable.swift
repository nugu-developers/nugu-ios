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

/// <#Description#>
public protocol StreamDataRoutable: UpstreamDataSendable {
    /// Adds a delegate to be notified of stream data handling states.
    ///
    /// - Parameter delegate: The object to add.
    func add(delegate: StreamDataDelegate)
    
    /// Removes a delegate from stream-data-router.
    ///
    /// - Parameter delegate: The object to remove.
    func remove(delegate: StreamDataDelegate)
    
    /// <#Description#>
    /// - Parameter completion: <#completion description#>
    func startReceiveServerInitiatedDirective(completion: ((StreamDataState) -> Void)?)
    
    /// <#Description#>
    /// - Parameter serverPolicy: <#serverPolicy description#>
    func startReceiveServerInitiatedDirective(to serverPolicy: Policy.ServerPolicy)
    
    /// <#Description#>
    func restartReceiveServerInitiatedDirective()
    
    /// <#Description#>
    func stopReceiveServerInitiatedDirective()
}
