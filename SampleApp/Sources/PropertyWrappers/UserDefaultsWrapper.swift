//
//  UserDefaultsWrapper.swift
//  SampleApp
//
//  Created by yonghoonKwon on 18/10/2019.
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
struct UserDefault<T> {
    let userDefaults: UserDefaults
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            return userDefaults.object(forKey: key) as? T ?? defaultValue
        } set {
            if let value = newValue as? OptionalProtocol, value.isNil() {
                userDefaults.removeObject(forKey: key)
            } else {
                userDefaults.set(newValue, forKey: key)
            }
        }
    }
}

// MARK: - OptionalProtocol

private protocol OptionalProtocol {
    func isNil() -> Bool
}

// MARK: - Optional+OptionalProtocol

extension Optional: OptionalProtocol {
    func isNil() -> Bool { self == nil }
}
