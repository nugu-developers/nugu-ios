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

struct NuguOAuthUtilApi {
    let token: String
    let clientId: String
    let clientSecret: String
    let deviceUniqueId: String
    let typeInfo: TypeInfo
    
    enum TypeInfo {
        case getUserInfo
        case revoke
    }
}

// MARK: - ApiProvidable

extension NuguOAuthUtilApi: ApiProvidable {
    var httpMethod: String {
        switch typeInfo {
        case .getUserInfo:
            return "POST"
        case .revoke:
            return "POST"
        }
    }
    
    var headers: [String: String] {
        switch typeInfo {
        case .getUserInfo:
            return [
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
            ]
        case .revoke:
            return [
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
            ]
        }
    }
    
    var uri: String {
        switch typeInfo {
        case .getUserInfo:
            return NuguOAuthServerInfo.serverBaseUrl + "/v1/auth/oauth/introspect"
        case .revoke:
            return NuguOAuthServerInfo.serverBaseUrl + "/v1/auth/oauth/revoke"
        }
    }
    
    var bodyParams: [String: String] {
        switch typeInfo {
        case .getUserInfo:
            return [
                "token": token,
                "client_id": clientId,
                "client_secret": clientSecret,
                "data": "{\"deviceSerialNumber\":\"\(deviceUniqueId)\"}"
            ]
        case .revoke:
            return [
                "token": token,
                "client_id": clientId,
                "client_secret": clientSecret,
                "data": "{\"deviceSerialNumber\":\"\(deviceUniqueId)\"}"
            ]
        }
    }
}
