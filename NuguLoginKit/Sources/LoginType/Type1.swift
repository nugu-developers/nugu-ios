//
//  Type1.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 01/10/2019.
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

/// The `Type1` authentication method that grant-type is authorization_code or refresh_token.
public class Type1: LoginType {
    
    /// The `ClientId` for OAuth authentication.
    public let clientId: String
    
    /// The `ClientSecret` for OAuth authentication.
    public let clientSecret: String
    
    /// The `redirectUri` for OAuth authentication.
    public let redirectUri: String
    
    /// The `deviceUniqueId` for OAuth authentication. Must be unique each device in your system.
    public let deviceUniqueId: String?
    
    /// The initializer for `Type1` authentication.
    public init(
        clientId: String,
        clientSecret: String,
        redirectUri: String,
        deviceUniqueId: String?) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
        self.deviceUniqueId = deviceUniqueId
    }
}
