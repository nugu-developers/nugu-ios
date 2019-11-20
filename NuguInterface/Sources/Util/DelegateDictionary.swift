//
//  DelegateDictionary.swift
//  NuguInterface
//
//  Created by MinChul Lee on 09/05/2019.
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

public class DelegateDictionary<Key, Value> {
    private let delegates: NSMapTable<AnyObject, AnyObject> = NSMapTable.strongToWeakObjects()
    
    public init() {
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return delegates.object(forKey: key as AnyObject) as? Value
        }
        set(newValue) {
            guard let value = newValue else { return }
            delegates.setObject(value as AnyObject, forKey: key as AnyObject)
        }
    }
    
    public func removeValue(forKey key: Key) {
        delegates.removeObject(forKey: key as AnyObject)
    }
    
    public func notify(_ body: (Value) -> Void) {
        delegates
            .objectEnumerator()?
            .compactMap({ (value) -> Value? in
                return value as? Value
            }).forEach({ (delegate) in
                body(delegate)
            })
    }
}
