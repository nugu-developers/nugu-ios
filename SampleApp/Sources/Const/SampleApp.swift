//
//  SampleApp.swift
//  SampleApp
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

import UIKit

import NattyLog

// MARK: - NattyLog

let log = Natty(by: nattyConfiguration)

private var nattyConfiguration: NattyConfiguration {
    return NattyConfiguration(
        minLogLevel: .debug,
        maxDescriptionLevel: .error,
        showPersona: true,
        prefix: "SampleApp"
    )
}

// MARK: - Url

struct SampleApp {
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
    
    /// Change variables according to your app
    static var loginMethod: LoginMethod? {
        return LoginMethod(rawValue: UserDefaults.Standard.loginMethod)
    }
}

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
    static let oauthRefresh = Notification.Name("com.skt.Romaine.oauth_refresh")
}
