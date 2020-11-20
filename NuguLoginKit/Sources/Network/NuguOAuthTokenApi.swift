//
//  NuguOAuthTokenApi.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 2020/01/06.
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

struct NuguOAuthTokenApi {
    let clientId: String
    let clientSecret: String
    let deviceUniqueId: String
    let grantTypeInfo: GrantTypeInfo
    
    enum GrantTypeInfo {
        case authorizationCode(code: String, redirectUri: String)
        case refreshToken(refreshToken: String)
        case clientCredentials
    }
}

// MARK: - ApiProvidable

extension NuguOAuthTokenApi: ApiProvidable {
    var httpMethod: String {
        return "post"
    }
    
    var headers: [String: String] {
        return ["Content-Type": "application/x-www-form-urlencoded; charset=utf-8"]
    }
    
    var uri: String {
        return NuguOAuthServerInfo.serverBaseUrl + "/v1/auth/oauth/token"
    }
    
    var bodyParams: [String: String] {
        switch grantTypeInfo {
        case .authorizationCode(let code, let redirectUri):
            return [
                "grant_type": "authorization_code",
                "client_id": clientId,
                "client_secret": clientSecret,
                "code": code,
                "redirect_uri": redirectUri,
                "data": "{\"deviceSerialNumber\":\"\(deviceUniqueId)\"}"
            ]
        case .refreshToken(let refreshToken):
            return [
                "grant_type": "refresh_token",
                "client_id": clientId,
                "client_secret": clientSecret,
                "refresh_token": refreshToken,
                "data": "{\"deviceSerialNumber\":\"\(deviceUniqueId)\"}"
            ]
        case .clientCredentials:
            return [
                "grant_type": "client_credentials",
                "client_id": clientId,
                "client_secret": clientSecret,
                "data": "{\"deviceSerialNumber\":\"\(deviceUniqueId)\"}"
            ]
        }
    }
}
