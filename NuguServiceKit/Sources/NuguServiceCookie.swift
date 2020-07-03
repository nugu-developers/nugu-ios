//
//  NuguServiceCookie.swift
//  NuguServiceKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/06/15.
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

public struct NuguServiceCookie: Encodable {
    let authToken: String
    let osTypeCode: String = "MBL_IOS" // CURRENTLY SUPPORT ONLY MBL_IOS
    let appVersion: String
    let sdkVersion: String
    let pocId: String
    let theme: String // DARK or LIGHT

    public init(
        authToken: String,
        appVersion: String,
        sdkVersion: String,
        pocId: String,
        theme: String
    ) {
        self.authToken = authToken
        self.appVersion = appVersion
        self.sdkVersion = sdkVersion
        self.pocId = pocId
        self.theme = theme
    }
    
    enum CodingKeys: String, CodingKey {
        case authToken = "Authorization"
        case osTypeCode = "Os-Type-Code"
        case appVersion = "App-Version"
        case sdkVersion = "Sdk-Version"
        case pocId = "Poc-Id"
        case theme = "Theme"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(authToken, forKey: .authToken)
        try container.encode(osTypeCode, forKey: .osTypeCode)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(pocId, forKey: .pocId)
        try container.encode(theme, forKey: .theme)
    }
}
