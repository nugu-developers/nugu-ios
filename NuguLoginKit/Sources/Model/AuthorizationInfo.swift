//
//  AuthorizationInfo.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 13/09/2019.
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

/// The `AuthorizationInfo` is result of oauth authentication.
public struct AuthorizationInfo: Decodable {
    
    /// Token for networking with device-gateway.
    public let accessToken: String
    
    /// Type of access-token.
    public let tokenType: String
    
    /// Required to refresh the access-token.
    ///
    /// If has a `refreshToken`, can request oauth authentication that grant-type is refresh_token.
    public let refreshToken: String?
    
    /// The authorization server uses the "scope" response parameter to inform the client of the scope of the access token issued.
    public let scopes: [String]
    private let scope: String?
    
    /// Expiration date of access-token.
    public let expireDate: Date
    private let expireTime: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case expireTime = "expires_in"
        case scope = "scope"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        accessToken = try container.decode(String.self, forKey: .accessToken)
        tokenType = try container.decode(String.self, forKey: .tokenType)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        expireTime = try container.decode(Int.self, forKey: .expireTime)
        scope = try container.decodeIfPresent(String.self, forKey: .scope)

        scopes = scope?.components(separatedBy: " ").filter { $0.count != 0 } ?? []
        expireDate = Date().addingTimeInterval(TimeInterval(expireTime))
    }
}
