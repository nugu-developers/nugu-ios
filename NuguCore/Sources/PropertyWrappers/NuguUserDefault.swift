//
//  NuguUserDefault.swift
//  JadeMarble
//
//  Created by MinChul Lee on 2020/08/31.
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

@propertyWrapper
public struct NuguUserDefault<T> {
    let userDefaults: UserDefaults
    let key: String
    let defaultValue: T
    
    public var wrappedValue: T {
        get {
            return userDefaults.object(forKey: key) as? T ?? defaultValue
        } set {
            userDefaults.set(newValue, forKey: key)
        }
    }
}

// MARK: - Custom

public extension UserDefaults {
    static let nugu = UserDefaults(suiteName: "group.com.sktelecom.nugu")!
}
