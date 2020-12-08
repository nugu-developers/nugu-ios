//
//  AuthorizationInfo+Scope.swift
//  NuguClientKit
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

import NuguLoginKit

public extension AuthorizationInfo {
    /// Indicates that the client can receive server initiated directives.
    var availableServerInitiatedDirective: Bool {
        scopes.contains("device:S.I.D")
    }
}
