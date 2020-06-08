//
//  NuguOAuthUtilApi.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 2020/06/03.
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

enum NuguOAuthUtilApi {
    case getUserInfo(token: String)
    case revoke(token: String, clientId: String, clientSecret: String)
}

// MARK: - ApiProvidable

extension NuguOAuthUtilApi: ApiProvidable {
    var httpMethod: String {
        switch self {
        case .getUserInfo:
            return "GET"
        case .revoke:
            return "POST"
        }
    }
    
    var headers: [String: String] {
        switch self {
        case .getUserInfo(let token):
            return [
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
                "Authorization": "Bearer \(token)"
            ]
        case .revoke:
            return [
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
            ]
        }
    }
    
    var uri: String {
        switch self {
        case .getUserInfo:
            return NuguOAuthServerInfo.serverBaseUrl + "/oauth/me"
        case .revoke:
            return NuguOAuthServerInfo.serverBaseUrl + "/oauth/revoke"
        }
    }
    
    var bodyParams: [String: String] {
        switch self {
        case .getUserInfo:
            return [:]
        case .revoke(let token, let clientId, let clientSecret):
            return [
                "token": token,
                "client_id": clientId,
                "client_secret": clientSecret
            ]
        }
    }
}
