//
//  SampleApp.swift
//  SampleApp-iOS
//
//  Created by yonghoonKwon on 25/06/2019.
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

import NattyLog

let log = SampleApp.natty

struct SampleApp {
    private static var nattyConfiguration: NattyConfiguration {
        return NattyConfiguration(minLogLevel: .debug,
                                  maxDescriptionLevel: .error,
                                  showPersona: true,
                                  prefix: "SampleApp")
    }
    
    fileprivate static let natty = Natty(by: nattyConfiguration)
    
    static var shownServiceSettingWeb = false
    
    static var serviceSettingWebUrl: URL? {
        get {
            guard shownServiceSettingWeb == false, let prefixUrl = URL(string: serviceSettingPrefixUrl) else {
                return nil
            }
            switch SampleApp.loginMethod {
            case .type1:
                var urlComponents = URLComponents(url: prefixUrl, resolvingAgainstBaseURL: false)
                urlComponents?.queryItems = [URLQueryItem(name: "poc", value: pocId)]
                return urlComponents?.url
            default:
                return nil
            }
        }
    }
    
    private static let serviceSettingPrefixUrl = "https://webview.sktnugu.com/v2/3pp/confirm.html"
    private static let pocId = "aaa.hmpark.vacation.ios" // Should replace with 3rd party's own pocId issued from Nugu Developers site
    
    /// Intercept open url and replace with redirectUri's scheme
    /// for free pass of Sample app's Oauth validation check
    /// Used only for Sample app (Clients should not use this code)
    /// - Parameter openUrl: url parameter from AppDelegate's application(_:open:options:) method for url scheme replacement
    static func schemeReplacedUrl(openUrl: URL) -> URL? {
        guard let redirectUri = redirectUri,
            let redirectUrlComponents = URLComponents(string: redirectUri),
            var openUrlComponents = URLComponents(url: openUrl, resolvingAgainstBaseURL: false) else { return nil }
        openUrlComponents.scheme = redirectUrlComponents.scheme
        guard let schemeReplacedUrl = openUrlComponents.url else { return nil }
        return schemeReplacedUrl
    }
}

// MARK: - Login Method

extension SampleApp {
    enum LoginMethod: Int, CaseIterable {
        /// Nugu App Link
        case type1 = 0
        /// Anonymous
        case type2 = 1
        
        var name: String {
            switch self {
            case .type1: return "Type 1"
            case .type2: return "Type 2"
            }
        }
    }
}

// MARK: - NuguServerType

extension SampleApp {
    enum NuguServerType {
        case stg
        case prd
    }
}

// MARK: - Sample data

extension SampleApp {
    /// Change variables according to your app
    
    /// Example for Type1
    ///
    /// static var loginMethod: LoginMethod? = .type1
    /// static var deviceUniqueId: String? = "{Unique-id per device}"
    /// static var clientId: String? = "{Client-id}" => Client-id is need for oauth-authorization
    /// static var clientSecret: String? = "{Client-secret}" => Client-secret is need for oauth-authorization
    /// static var redirectUri: String? = "{Redirect-uri}" => Redirect-uri is need for oauth-authorization
    
    /// Example for Type2
    ///
    /// static var loginMethod: LoginMethod? = .type1
    /// static var deviceUniqueId: String? = "{Unique-id per device}"
    /// static var clientId: String? = "{Client-id}" => Client-id is need for oauth-authorization
    /// static var clientSecret: String? = "{Client-secret}" => Client-secret is need for oauth-authorization
    
    // Common
    static var loginMethod: LoginMethod? {
        return LoginMethod(rawValue: UserDefaults.Romaine.loginMethod)
    }
    static var deviceUniqueId: String? {
        return UserDefaults.Romaine.deviceUniqueId
    }
    static var clientId: String? {
        return UserDefaults.Romaine.clientId
    }
    static var clientSecret: String? {
        return UserDefaults.Romaine.clientSecret
    }
    
    // Link App (Type 1)
    static var redirectUri: String? {
        return UserDefaults.Romaine.redirectUri
    }
}

// MARK: - Safe Area

extension SampleApp {
    static var bottomSafeAreaHeight: CGFloat {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return 0 }
        if #available(iOS 11.0, *) {
            return rootViewController.view.safeAreaInsets.bottom
        } else {
            return rootViewController.bottomLayoutGuide.length
        }
    }
}

// MARK: - Notification.Name

extension Notification.Name {
    static let login = Notification.Name("com.skt.Romaine.login")
}
