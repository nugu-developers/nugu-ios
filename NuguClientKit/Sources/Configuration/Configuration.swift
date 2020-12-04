//
//  Configuration.swift
//  NuguClientKit
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/11/13.
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

import NuguLoginKit

public struct Configuration: Decodable {
    public var authServerUrl: String
    public var authClientId: String
    public var authClientSecret: String
    public var authRedirectUri: String
    public var pocId: String
    public var deviceTypeCode: String

    enum CodingKeys: String, CodingKey {
        case authServerUrl = "OAuthServerUrl"
        case authClientId = "OAuthClientId"
        case authClientSecret = "OAuthClientSecret"
        case authRedirectUri = "OAuthRedirectUri"
        case pocId = "PoCId"
        case deviceTypeCode = "DeviceTypeCode"
    }
    
    public init(
        authServerUrl: String,
        authClientId: String,
        authClientSecret: String,
        authRedirectUri: String,
        pocId: String,
        deviceTypeCode: String
    ) {
        self.authServerUrl = authServerUrl
        self.authClientId = authClientId
        self.authClientSecret = authClientSecret
        self.authRedirectUri = authRedirectUri
        self.pocId = pocId
        self.deviceTypeCode = deviceTypeCode
    }
}

// MAKR: - Url

public extension Configuration {
    var serviceWebRedirectUri: String {
        authRedirectUri + "_refresh"
    }
    var discoveryUri: String {
        "\(authServerUrl)/.well-known/oauth-authorization-server/\(authClientId)"
    }
}
