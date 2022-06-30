//
//  UserDefaults+Standard.swift
//  SampleApp
//
//  Created by yonghoonKwon on 06/07/2019.
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
import NuguClientKit

extension UserDefaults {
    enum Standard {
        // MARK: Setting
        
        @UserDefault(userDefaults: .standard, key: "loginMethod", defaultValue: -1)
        static var loginMethod: Int
        
        @UserDefault(userDefaults: .standard, key: "theme", defaultValue: 0)
        static var theme: Int
        
        /// Setting value for using nugu service.
        @UserDefault(userDefaults: .standard, key: "useNuguService", defaultValue: true)
        static var useNuguService: Bool
      
        /// Setting value for using wakeup dectector.
        @UserDefault(userDefaults: .standard, key: "useWakeUpDetector", defaultValue: true)
        static var useWakeUpDetector: Bool
        
        /// Setting value for using wakeup dectector, default value is "aria".
        @UserDefault(userDefaults: .standard, key: "wakeUpWord", defaultValue: 0)
        static var wakeUpWord: Int // Deprecated => need to migration
        
        /// Setting value for using wakeup detector's description, default value is "aria".
        @UserDefault(
            userDefaults: .standard,
            key: "wakeUpWordDictionary",
            defaultValue: [
                "rawValue": String(Keyword.aria.rawValue)
//                "description": "",
//                "netFileName": "",
//                "searchFileName": ""
            ]
        )
        static var wakeUpWordDictionary: [String: String]
        
        /// Setting value whether or not to use beep when starts speech recognition.
        @UserDefault(userDefaults: .standard, key: "useAsrStartSound", defaultValue: true)
        static var useAsrStartSound: Bool
        
        /// Setting value whether or not to use beep after success speech recognition.
        @UserDefault(userDefaults: .standard, key: "useAsrSuccessSound", defaultValue: true)
        static var useAsrSuccessSound: Bool
        
        /// Setting value whether or not to use beep after fail speech recognition.
        @UserDefault(userDefaults: .standard, key: "useAsrFailSound", defaultValue: true)
        static var useAsrFailSound: Bool
        
        // MARK: Auth
        
        /// A refresh-token allows an application to obtain a new access-token without prompting the user.
        @UserDefault(userDefaults: .standard, key: "refreshToken", defaultValue: nil)
        static var refreshToken: String?
        
        /// Authorization token for networking with nugu received as a result of oauth.
        @UserDefault(userDefaults: .standard, key: "accessToken", defaultValue: nil)
        static var accessToken: String?
        
        // MARK: LoginType
        
        /// Not neccesary for your app.
        /// It is only needed for the login type(tid, anonymous) in the sample app.
        /// Default value is tid.
        @UserDefault(userDefaults: .standard, key: "currentloginMethod", defaultValue: 0)
        static var currentloginMethod: Int
        
        @UserDefault(userDefaults: .standard, key: "hasSeenGuideWeb", defaultValue: false)
        static var hasSeenGuideWeb: Bool
    }
}

// MARK: - Helper

extension UserDefaults.Standard {
    static func clear() {
        UserDefaults.standard
            .dictionaryRepresentation()
            .keys
            .forEach({ (key) in
                UserDefaults.standard.removeObject(forKey: key)
            })
    }
}
