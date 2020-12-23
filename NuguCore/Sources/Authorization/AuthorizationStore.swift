//
//  AuthorizationStore.swift
//  NuguCore
//
//  Created by MinChul Lee on 26/04/2019.
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

public class AuthorizationStore: AuthorizationStoreable {
    public static let shared = AuthorizationStore()
    
    public weak var delegate: AuthorizationStoreDelegate?
    
    public var accessToken: String? {
        guard let delegate = delegate else { return nil }
        return delegate.authorizationStoreRequestAccessToken()
    }
    
    public var authorizationToken: String? {
        guard let accessToken = accessToken else { return nil }
        return "Bearer \(accessToken)"
    }
}
