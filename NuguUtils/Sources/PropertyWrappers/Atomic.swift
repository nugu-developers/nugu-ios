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
    private let queue = DispatchQueue(label: "com.sktelecom.romaine.atomic.queue")
    private var thread: Thread!

    public init(wrappedValue value: Value) {
        self.value = value
        
        queue.async { [weak self] in
            self?.thread = Thread.current
        }
    }

    public var wrappedValue: Value {
      get { return load() }
      set { store(value: newValue) }
    }

    private func load() -> Value {
        guard Thread.current != thread else {
            fatalError("You load same thread on synchronization. queue: \(queue.label) \nbt: \(Thread.callStackSymbols.joined(separator: "\n"))")
        }
        
        return queue.sync { () -> Value in
            return value
        }
    }

    private func store(value: Value) {
        guard Thread.current != thread else {
            fatalError("You store same thread on synchronization. \nbt: \(Thread.callStackSymbols.joined(separator: "\n"))")
        }
        
        queue.sync {
            self.value = value
        }
    }
    
    public func mutate(_ transform: (inout Value) -> Void) {
        guard Thread.current != thread else {
            fatalError("You transform same thread on synchronization. \nbt: \(Thread.callStackSymbols.joined(separator: "\n"))")
        }
        
        queue.sync {
            transform(&value)
        }
    }
}
