//
//  AuthorizationStoreable.swift
//  NuguInterface
//
//  Created by MinChul Lee on 2019/12/06.
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

/// The `AuthorizationStoreable` is used to provide authorization token.
/// Provide authorization token
public protocol AuthorizationStoreable: class {
    /// An delegate that application should extend to provide access token.
    var delegate: AuthorizationStoreDelegate? { get set }
    
    /// Get the current authorization token
    ///
    /// - returns: The current authorization token. (auth_type + access_token)
    func requestAuthorization() -> String?
}
