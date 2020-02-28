//
//  NetworkManageable.swift
//  NuguCore
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

import RxSwift

/// <#Description#>
public protocol NetworkManageable: class {
    /**
     Connection state of stream receive server-initiated directive
     */
    var isConnected: Bool { get }

    /**
     Connect stream receive server-initiated directive
     */
    func connect(completion: ((Result<Void, Error>) -> Void)?)
    
    /**
     Disconnect stream receive server-initiated directive
     */
    func disconnect()
    
    func sendMessage(inputStream: InputStream) -> Observable<MultiPartParser.Part>

    func add(statusDelegate: NetworkStatusDelegate)
    func remove(statusDelegate: NetworkStatusDelegate)

    func add(receiveMessageDelegate: ReceiveMessageDelegate)
    func remove(receiveMessageDelegate: ReceiveMessageDelegate)
}

public extension NetworkManageable {
    func connect() {
        connect(completion: nil)
    }
}
