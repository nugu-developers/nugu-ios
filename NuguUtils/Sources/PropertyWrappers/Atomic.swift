//
//  Atomic.swift
//  NuguUtils
//
//  Created by childc on 2019/10/24.
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
final public class Atomic<Value> {
    private var value: Value
    private let lock = NSRecursiveLock()

    public init(wrappedValue value: Value) {
        self.value = value
    }

    public var wrappedValue: Value {
      get { return load() }
      set { store(value: newValue) }
    }

    private func load() -> Value {
        return lock.withLock {
            return value
        }
    }

    private func store(value: Value) {
        lock.withLock {
            self.value = value
        }
    }
    
    public func mutate(_ transform: (inout Value) -> Void) {
        lock.withLock {
            transform(&value)
        }
    }
}
