//
//  NetworkManageable.swift
//  NuguInterface
//
//  Created by MinChul Lee on 19/04/2019.
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
public protocol NetworkManageable: class {
    var apiProvider: NuguApiProvideable? { get }
    /// <#Description#>
    var connected: Bool { get }
    /// <#Description#>
    /// - Parameter completion: <#completion description#>
    func connect(completion: ((Result<Void, Error>) -> Void)?)
    /// <#Description#>
    func disconnect()
    /// <#Description#>
    /// - Parameter statusDelegate: <#statusDelegate description#>
    func add(statusDelegate: NetworkStatusDelegate)
    /// <#Description#>
    /// - Parameter statusDelegate: <#statusDelegate description#>
    func remove(statusDelegate: NetworkStatusDelegate)
    
    /// <#Description#>
    /// - Parameter receiveMessageDelegate: <#receiveMessageDelegate description#>
    func add(receiveMessageDelegate: ReceiveMessageDelegate)
    
    /// <#Description#>
    /// - Parameter receiveMessageDelegate: <#receiveMessageDelegate description#>
    func remove(receiveMessageDelegate: ReceiveMessageDelegate)
}

public extension NetworkManageable {
    func connect() {
        connect(completion: nil)
    }
}
