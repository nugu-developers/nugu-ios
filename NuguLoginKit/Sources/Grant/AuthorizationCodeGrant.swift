//
//  AuthorizationCodeGrant.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 2019/12/21.
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
public struct AuthorizationCodeGrant {
    /// The `clientId` for OAuth authentication.
    public let clientId: String
    /// The `clientSecret` for OAuth authentication.
    public let clientSecret: String
    /// The `redirectUri` for OAuth authentication.
    public let redirectUri: String
    
    /// The initializer for `AuthorizationCodeGrant`.
    /// - Parameter clientId: The `clientId` for OAuth authentication.
    /// - Parameter clientSecret: The `clientSecret` for OAuth authentication.
    /// - Parameter redirectUri: The `redirectUri` for OAuth authentication.
    public init(clientId: String, clientSecret: String, redirectUri: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
    }
}
