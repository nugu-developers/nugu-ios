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
        case tid = 0
        /// Anonymous
        case anonymous = 1
        
        var name: String {
            switch self {
            case .tid: return "T-ID"
            case .anonymous: return "Anonymous"
            }
        }
    }
    
    /// Change variables according to your app
    static var loginMethod: LoginMethod? {
        return LoginMethod(rawValue: UserDefaults.Standard.loginMethod)
    }
    
    enum Theme: Int, CaseIterable {
        case system
        case light
        case dark
        
        var name: String {
            switch self {
            case .system: return "시스템 설정 모드"
            case .light: return "라이트 모드"
            case .dark: return "다크 모드"
            }
        }
    }
    
    static var theme: Theme? {
        return Theme(rawValue: UserDefaults.Standard.theme)
    }
}

// MARK: - Notification.Name

extension Notification.Name {
    static let oauthRefreshNotification = Notification.Name("com.sktelecom.romaine.SampleApp.oauth_refresh")
    static let nuguServiceStateDidChangeNotification = Notification.Name("com.sktelecom.romaine.SampleApp.nugu_service_state_did_change")
    static let speechStateDidChangeNotification = Notification.Name("com.sktelecom.romaine.SampleApp.speech_state_did_change")
    static let dialogStateDidChangeNotification = Notification.Name("com.sktelecom.romaine.SampleApp.dialog_state_did_change")
}
