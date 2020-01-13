//
//  ClientCredentialsGrant.swift
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

public class ClientCredentialsGrant {
    public let clientId: String
    public let clientSecret: String
    
    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
    
    public func authorize(deviceUniqueId: String, completion: ((Result<AuthorizationInfo, Error>) -> Void)?) {
        let api = NuguOAuthApi(
            clientId: clientId,
            clientSecret: clientSecret,
            deviceUniqueId: deviceUniqueId,
            grantTypeInfo: .clientCredentials
        )
        
        api.request(completion: completion)
    }
}
