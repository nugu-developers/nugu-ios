//
//  WeakSet.swift
//  NuguUtils
//
//  Created by DCs-MBP on 2020/11/19.
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

public class WeakSet<Element> where Element: AnyObject, Element: Hashable {
    private let hashTable: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    public init() {}
    
    public func insert(_ newMember: Element) {
        hashTable.add(newMember)
    }
    
    public func remove(_ memeber: Element) {
        hashTable.remove(memeber)
    }
    
    public var allObjects: [Element] {
        return hashTable.allObjects.compactMap { $0 as? Element }
    }
}
