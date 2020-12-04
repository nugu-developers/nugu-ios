//
//  NuguClient+Configuration.swift
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

import Foundation

import NuguCore
import NuguLoginKit
import NuguUtils

public extension NuguOAuthClient {
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
        showTidInfo(grant: grant, token: token, parentViewController: parentViewController, completion: completion)
    }
    
    func authorize(parentViewController: UIViewController, completion: @escaping (Result<AuthorizationInfo, NuguLoginKitError>) -> Void) {
        guard let configuration = ConfigurationStore.shared.configuration else {
            completion(.failure(.unknown(description: "ConfigurationStore is not configured")))
            return
        }
        
        let grant = AuthorizationCodeGrant(
            clientId: configuration.authClientId,
            clientSecret: configuration.authClientSecret,
            redirectUri: configuration.authRedirectUri
        )
        authorize(grant: grant, parentViewController: parentViewController, completion: completion)
    }
    
    func refreshToken(refreshToken: String, completion: @escaping (Result<AuthorizationInfo, NuguLoginKitError>) -> Void) {
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
    
    func authorize(completion: @escaping (Result<AuthorizationInfo, NuguLoginKitError>) -> Void) {
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
