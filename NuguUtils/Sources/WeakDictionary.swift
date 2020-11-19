//
//  WeakDictionary.swift
//  NuguUtils
//
//  Created by childc on 2020/11/19.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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

import Foundation

public class WeakDictionary<Key: AnyObject, Value: AnyObject> {
    private let mapTable: NSMapTable<Key, Value>
    
    public enum WeakType {
        case key
        case value
        case all
    }
    
    public init(type: WeakType) {
        switch type {
        case .key:
            mapTable = NSMapTable<Key, Value>.weakToStrongObjects()
        case .value:
            mapTable = NSMapTable<Key, Value>.strongToWeakObjects()
        case .all:
            mapTable = NSMapTable<Key, Value>.weakToWeakObjects()
        }
    }
    
    subscript(key: Key) -> Value? {
        get { mapTable.object(forKey: key) }
        set { mapTable.setObject(newValue, forKey: key) }
    }
    
    public var keys: [Key] {
        return mapTable.keyEnumerator().allObjects.compactMap { $0 as? Key }
    }
    
    public var values: [Value]? {
        return mapTable.objectEnumerator()?.allObjects.compactMap { $0 as? Value }
    }
}
