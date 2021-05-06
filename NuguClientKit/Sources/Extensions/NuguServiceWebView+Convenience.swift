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
import UIKit

import NuguCore
import NuguServiceKit
import NuguUtils

public extension NuguServiceWebView {
    /// Add cookie to `NuguServiceWebView` which already has default cookie
    /// - Parameter cookie: Custom dictionary for user specific cookie setting.
    ///                     Value will be overwrited when the key is same with default cookie.
    ///                     Few keys are provided as `NuguServiceCookieKey` and for more custom keys, extend `NuguServiceCookieKey`
    func addCookie(_ cookie: [NuguServiceCookieKey.RawValue: Any]?) {
        guard let configuration = ConfigurationStore.shared.configuration else {
            log.error("ConfigurationStore is not configured")
            return
        }
        guard let token = AuthorizationStore.shared.authorizationToken else {
            log.error("Access token is nil")
            return
        }
        let defaultCookieDictionary: [String: Any] = [
            "Authorization": token,
            "Os-Type-Code": "MBL_IOS",
            "App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            "Sdk-Version": Bundle(identifier: "com.sktelecom.romaine.NuguServiceKit")?.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            "Poc-Id": configuration.pocId,
            "Phone-Model-Name": UIDevice.current.model,
            "Theme": "LIGHT",
            "Oauth-Redirect-Uri": configuration.serviceWebRedirectUri
        ]
        guard let cookie = cookie else {
            setCookie(defaultCookieDictionary)
            return
        }
        let mergedCookie = defaultCookieDictionary.merged(with: cookie)
        log.debug(mergedCookie)
        setCookie(mergedCookie)
    }
}
