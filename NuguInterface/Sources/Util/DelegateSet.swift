//
//  DelegateSet.swift
//  Nugu
//
//  Created by MinChul Lee on 17/04/2019.
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

public class DelegateSet<T> {
    private let delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    public init() {
    }
    
    public func add(_ delegate: T) {
        delegates.add(delegate as AnyObject)
    }
    
    public func remove(_ delegate: T) {
        delegates.remove(delegate as AnyObject)
    }
    
    public func notify(_ body: (T) -> Void) {
        allObjects.forEach({ (value) in
                body(value)
            })
    }
    
    public var allObjects: [T] {
        return delegates.allObjects.compactMap { $0 as? T }
    }
}
