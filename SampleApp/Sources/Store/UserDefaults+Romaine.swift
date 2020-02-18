//
//  UserDefaults+Romaine.swift
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

extension UserDefaults {
    enum Romaine {
        // MARK: Login Type
        
        @UserDefault(userDefaults: .romaine, key: "loginMethod", defaultValue: 0)
        static var loginMethod: Int
        
        // MARK: Common Parameters
        
        @UserDefault(userDefaults: .romaine, key: "clientId", defaultValue: nil)
        static var clientId: String?
        
        @UserDefault(userDefaults: .romaine, key: "clientSecret", defaultValue: nil)
        static var clientSecret: String?
        
        @UserDefault(userDefaults: .romaine, key: "deviceUniqueId", defaultValue: nil)
        static var deviceUniqueId: String?
        
        // MARK: For Type1
        
        @UserDefault(userDefaults: .romaine, key: "redirectUri", defaultValue: nil)
        static var redirectUri: String?
    }
}

// MARK: - Helper

extension UserDefaults.Romaine {
    static func clear() {
        UserDefaults.romaine
            .dictionaryRepresentation()
            .keys
            .forEach({ (key) in
                UserDefaults.standard.removeObject(forKey: key)
            })
    }
}
