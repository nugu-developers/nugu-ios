//
//  NuguLoginError.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 16/09/2019.
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

enum ApiError: Error {
    case nilValue(description: String)
}

/// The `LoginError` is error of authentication method with `OAuthManager`
public enum LoginError: Error {
    /// `OAuthManager` has no `loginTypeInfo`.
    case noLoginTypeInfo
    
    /// The URL to which are trying to send a request is invalid.
    case invalidRequestURL
    
    /// The URL received by AppDelegate is invalid.
    ///
    /// The error occurs when receive any URL other than redirectURI during OAuth authentication process.
    case invalidOpenURL
    
    /// The authorization-code received by AppDelegate is invalid.
    case noAuthorizationCode
    
    /// The state received by AppDelegate is invalid.
    case invalidState
    
    /// The error occurs when called `safariViewControllerDidFinish` by `SFSafariViewControllerDelegate` during OAuth authentication process.
    case didFinishSafariViewController
    
    /// The error occurs when request OAuth authentication API.
    case network(error: Error)
}
