//
//  Atomic.swift
//  JadeMarble
//
//  Created by childc on 2019/10/24.
//

import Foundation

@propertyWrapper
struct Atomic<Value> {
    private var value: Value
    private let queue = DispatchQueue(label: "com.sktelecom.romaine.atomic.queue")

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
      get { return load() }
      set { store(value: newValue) }
    }

    func load() -> Value {
        return queue.sync { () -> Value in
            return value
        }
    }

    mutating func store(value: Value) {
        queue.sync {
            self.value = value
        }
    }
}
