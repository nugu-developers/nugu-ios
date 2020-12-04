//
//  NuguServiceWebView+Convenience.swift
//  NuguClientKit
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/12/04.
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

import NuguCore
import NuguServiceKit

public extension NuguServiceWebView {
    func setNuguServiceCookie(theme: String = "LIGHT") {
        guard let configuration = ConfigurationStore.shared.configuration else {
            log.error("ConfigurationStore is not configured")
            return
        }
        guard let token = AuthorizationStore.shared.authorizationToken else {
            log.error("Access token is nil")
            return
        }
        
        let cookie = NuguServiceCookie(
            authToken: token,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            pocId: configuration.pocId, // Put your own pocId
            theme: theme,
            oauthRedirectUri: configuration.serviceWebRedirectUri
        )
        setNuguServiceCookie(nuguServiceCookie: cookie)
    }
}
