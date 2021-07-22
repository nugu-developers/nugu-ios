//
//  NuguOAuthClient+Configuration.swift
//  NuguClientKit
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/12/01.
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

import UIKit

import NuguCore
import NuguLoginKit
import NuguUtils

public extension NuguOAuthClient {
    /// Get some NUGU member information.
    ///
    /// `ConfigurationStore` must be configured.
    /// - Parameter completion: The closure to receive result for getting NUGU member information.
    func getUserInfo(completion: @escaping (Result<NuguUserInfo, NuguLoginKitError>) -> Void) {
        guard let configuration = ConfigurationStore.shared.configuration else {
            completion(.failure(.unknown(description: "ConfigurationStore is not configured")))
            return
        }
        guard let token = AuthorizationStore.shared.accessToken else {
            completion(.failure(.unknown(description: "Access token is nil")))
            return
        }
        
        getUserInfo(clientId: configuration.authClientId, clientSecret: configuration.authClientSecret, token: token, completion: completion)
    }
    
    /// Shows web-page where TID information can be modified with `AuthorizationCode` grant type.
    ///
    /// `ConfigurationStore` must be configured.
    /// - Parameters:
    ///   - parentViewController: The `parentViewController` will present a safariViewController.
    ///   - completion: The closure to receive result for authorization.
    func showTidInfo(parentViewController: UIViewController, completion: @escaping (Result<AuthorizationInfo, NuguLoginKitError>) -> Void) {
        guard let configuration = ConfigurationStore.shared.configuration else {
            completion(.failure(.unknown(description: "ConfigurationStore is not configured")))
            return
        }
        guard let token = AuthorizationStore.shared.accessToken else {
            completion(.failure(.unknown(description: "Access token is nil")))
            return
        }
    
        let grant = AuthorizationCodeGrant(
            clientId: configuration.authClientId,
            clientSecret: configuration.authClientSecret,
            redirectUri: configuration.authRedirectUri
        )
        showTidInfo(
            grant: grant,
            token: token,
            parentViewController: parentViewController,
            theme: WebTheme(rawValue: configuration.theme) ?? .light,
            completion: completion
        )
    }
    
    /// Authorize with `AuthorizationCode` grant type.
    ///
    /// `ConfigurationStore` must be configured.
    /// - Parameter parentViewController: The `parentViewController` will present a safariViewController.
    /// - Parameter completion: The closure to receive result for authorization.
    func loginWithTid(
        parentViewController: UIViewController,
        completion: @escaping (Result<AuthorizationInfo, NuguLoginKitError>) -> Void
    ) {
        guard let configuration = ConfigurationStore.shared.configuration else {
            completion(.failure(.unknown(description: "ConfigurationStore is not configured")))
            return
        }
        
        let grant = AuthorizationCodeGrant(
            clientId: configuration.authClientId,
            clientSecret: configuration.authClientSecret,
            redirectUri: configuration.authRedirectUri
        )
        authorize(
            grant: grant,
            parentViewController: parentViewController,
            theme: WebTheme(rawValue: configuration.theme) ?? .light,
            completion: completion
        )
    }
    
    /// Authorize with `RefreshToken` grant type.
    ///
    /// `ConfigurationStore` must be configured.
    /// - Parameter refreshToken: The `refreshToken` for OAuth authentication.
    /// - Parameter completion: The closure to receive result for authorization.
    func loginSilentlyWithTid(
        refreshToken: String,
        completion: @escaping (Result<AuthorizationInfo, NuguLoginKitError>) -> Void
    ) {
        guard let configuration = ConfigurationStore.shared.configuration else {
            completion(.failure(.unknown(description: "ConfigurationStore is not configured")))
            return
        }
        
        let grant = RefreshTokenGrant(
            clientId: configuration.authClientId,
            clientSecret: configuration.authClientSecret,
            refreshToken: refreshToken
        )
        authorize(grant: grant, completion: completion)
    }
    
    /// Authorize with `ClientCredentials` grant type.
    ///
    /// `ConfigurationStore` must be configured.
    /// - Parameter completion: The closure to receive result for authorization.
    func loginAnonymously(completion: @escaping (Result<AuthorizationInfo, NuguLoginKitError>) -> Void) {
        guard let configuration = ConfigurationStore.shared.configuration else {
            completion(.failure(.unknown(description: "ConfigurationStore is not configured")))
            return
        }
        
        let grant = ClientCredentialsGrant(
            clientId: configuration.authClientId,
            clientSecret: configuration.authClientSecret
        )
        authorize(grant: grant, completion: completion)
    }
    
    /// Revoke completly with NUGU
    /// 
    /// `ConfigurationStore` must be configured.
    /// - Parameters:
    ///   - completion: The closure to receive result for `revoke`.
    func revoke(completion: @escaping (EndedUp<NuguLoginKitError>) -> Void) {
        guard let configuration = ConfigurationStore.shared.configuration else {
            completion(.failure(.unknown(description: "ConfigurationStore is not configured")))
            return
        }
        guard let token = AuthorizationStore.shared.accessToken else {
            completion(.failure(.unknown(description: "Access token is nil")))
            return
        }
        
        revoke(clientId: configuration.authClientId, clientSecret: configuration.authClientSecret, token: token, completion: completion)
    }
}
