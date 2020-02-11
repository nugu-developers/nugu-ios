//
//  NetworkManagerMock.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2020/02/11.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

import NuguCore

class MockNetworkManager: NetworkManageable {
    var apiProvider: NuguApiProvidable? = nil
    var networkStatus: NetworkStatus = .disconnected() {
        didSet {
            guard oldValue != networkStatus else { return }
            
            networkStatusDelegates.notify{ $0.networkStatusDidChange(networkStatus) }
        }
    }
    
    var connected: Bool {
        return networkStatus == .connected
    }
    
    private let receiveMessageDelegates = DelegateSet<ReceiveMessageDelegate>()
    private let networkStatusDelegates = DelegateSet<NetworkStatusDelegate>()
    
    init() {}
    
    func connect(completion: ((Result<Void, Error>) -> Void)?) {
        networkStatus = .connected
        completion?(.success(()))
    }
    
    func disconnect() {
        networkStatus = .disconnected()
    }
    
    func add(statusDelegate: NetworkStatusDelegate) {
        networkStatusDelegates.add(statusDelegate)
    }
    
    func remove(statusDelegate: NetworkStatusDelegate) {
        networkStatusDelegates.remove(statusDelegate)
    }
    
    func add(receiveMessageDelegate delegate: ReceiveMessageDelegate) {
        receiveMessageDelegates.add(delegate)
    }
    
    func remove(receiveMessageDelegate delegate: ReceiveMessageDelegate) {
        receiveMessageDelegates.remove(delegate)
    }
}
