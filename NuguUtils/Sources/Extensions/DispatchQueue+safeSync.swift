//
//  DispatchQueue+safeSync.swift
//  NuguUtils
//
//  Created by childc on 2020/11/13.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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

fileprivate class DispatchQueueManager {
    static let shared = DispatchQueueManager()
    @Atomic var keys = [Int: DispatchSpecificKey<Int>]()
}

fileprivate extension DispatchQueue {
    func setSpecificKey() {
        let specificKey = DispatchSpecificKey<Int>()
        DispatchQueueManager.shared.keys[hashValue] = specificKey
        setSpecific(key: specificKey, value: hashValue)
    }
    
    var isCurrentSpecific: Bool {
        guard let specificKey = DispatchQueueManager.shared.keys[hashValue],
              DispatchQueue.getSpecific(key: specificKey) == hashValue else {
            return false
        }
        
        return true
    }
}

/**
 SafeSync

 Check current queue and run the `DispatchWorkItem` or `Thunk`
 - seeAlso: `DispatchQueue`
 */
public extension DispatchQueue {
    /**
     Supports collision free sync method
     - parameter safety: support it or not
     */
    convenience init(label: String, qos: DispatchQoS = .unspecified, attributes: Attributes = [], autoreleaseFrequency: AutoreleaseFrequency = .inherit, target: DispatchQueue? = nil, safety: Bool) {
        self.init(label: label, qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: target)
        
        if safety {
            setSpecificKey()
        }
    }
    
    /**
     Supports collision free sync method
     
     - parameter safety: support it or not
     */
    convenience init(label: String, safety: Bool) {
        self.init(label: label)
        
        if safety {
            setSpecificKey()
        }
    }
    
    /**
     Collision free sync method
     
     If this method called on the same queue, It won't process thread-related thigs.
     */
    func safeSync(execute workItem: DispatchWorkItem) {
        guard isCurrentSpecific == false else {
            return
        }
        
        sync(execute: workItem)
    }
    
    /**
     Collision free sync method
     
     If this method called on the same queue, It won't process thread-related thigs.
     */
    func safeSync<T>(execute work: () throws -> T) rethrows -> T {
        guard isCurrentSpecific == false else {
            return try work()
        }
        
        return try sync(execute: work)
    }
    
    /**
     Collision free sync method
     
     If this method called on the same queue, It won't process thread-related thigs.
     */
    func safeSync<T>(flags: DispatchWorkItemFlags, execute work: () throws -> T) rethrows -> T {
        guard isCurrentSpecific == false else {
            return try work()
        }
        
        return try sync(flags: flags, execute: work)
    }
    
    /**
     Collision free sync method.
     
     If this method called on the same queue, It won't process thread-related thigs.
     But Just run the block.
     */
    func safeSync(execute block: () -> Void) {
        guard isCurrentSpecific == false else {
            block()
            return
        }
        
        sync(execute: block)
    }
}
