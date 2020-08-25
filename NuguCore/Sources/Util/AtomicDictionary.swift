//
//  AtomicDictionary.swift
//  NuguCore
//
//  Created by MinChul Lee on 2020/04/22.
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

// FIXME: Modify `class` to `struct` for better performance.
final class AtomicDictionary<Key: Hashable, Value> {
    private let dictionaryQueue = DispatchQueue(label: "com.sktelecom.romaine.atomic_dictionary", attributes: .concurrent)
    
    private var dictionary = [Key: Value]()
    
    var keys: Dictionary<Key, Value>.Keys {
        dictionaryQueue.sync {
            dictionary.keys
        }
    }
    var values: Dictionary<Key, Value>.Values {
        dictionaryQueue.sync {
            dictionary.values
        }
    }
    
    subscript(key: Key) -> Value? {
        get {
            dictionaryQueue.sync {
                dictionary[key]
            }
        }
        set {
            // FIXME: Modify `async` to `sync` for better performance.
            dictionaryQueue.async(flags: .barrier) { [weak self] in
                self?.dictionary[key] = newValue
            }
        }
    }
}
