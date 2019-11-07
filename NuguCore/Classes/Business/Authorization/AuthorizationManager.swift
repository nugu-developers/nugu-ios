//
//  AuthorizationManager.swift
//  NuguCore
//
//  Created by MinChul Lee on 28/04/2019.
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

import NuguInterface

public class AuthorizationManager: AuthorizationManageable {
    public static let shared = AuthorizationManager()
    
    private let authorizationDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.authorization_manager", qos: .userInitiated)
    
    private let authorizationStateDelegates = DelegateSet<AuthorizationStateDelegate>()
    public var authorizationPayload: AuthorizationPayload? {
        didSet {
            authorizationDispatchQueue.async { [weak self] in
                if self?.authorizationPayload != nil {
                    self?.authorizationState = .refreshed
                } else {
                    self?.authorizationState = .uninitialized
                }
            }
        }
    }
    private var authorizationState: AuthorizationState = .uninitialized {
        didSet {
            log.info("\(oldValue) \(authorizationState)")

            authorizationStateDelegates.notify { delegate in
                delegate.authorizationStateDidChange(authorizationState)
            }
        }
    }

    private init() {
        log.info("")
    }

    deinit {
        log.info("")
    }
}

// MARK: - AuthorizationManageable

extension AuthorizationManager {
    public func add(stateDelegate: AuthorizationStateDelegate) {
        authorizationStateDelegates.add(stateDelegate)
    }

    public func remove(stateDelegate: AuthorizationStateDelegate) {
        authorizationStateDelegates.remove(stateDelegate)
    }
}

// MARK: - SystemAgentDelegate

extension AuthorizationManager: SystemAgentDelegate {
    public func systemAgentDidReceiveAuthorizationError() {
        authorizationDispatchQueue.async { [weak self] in
            self?.authorizationState = .error(.authorizationFailed)
        }
    }
}
