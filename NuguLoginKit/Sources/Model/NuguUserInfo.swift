//
//  NuguUserInfo.swift
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

/// The `NuguUserInfo` is simple profile in NUGU
public struct NuguUserInfo: Decodable {
    
    /// The `active` is indicates the NUGU's activation status.
    public let active: Bool
    
    /// The `username` used by NUGU users
    public let username: String?
}
