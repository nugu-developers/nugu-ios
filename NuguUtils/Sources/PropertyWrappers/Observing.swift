//
//  Observing.swift
//  NuguUtils
//
//  Created by childc on 2021/01/07.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
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
public class Observing<Value: Equatable> {
    private var value: Value
    @Atomic private var nextId = 0
    private lazy var observerContainer: ObserverContainer = ObserverContainer(self)
    
    public var notificationQueue: DispatchQueue?
    public var additionalInfo: [String: Any]?
    public var duplicatedNotify = true
    
    public init(wrappedValue: Value) {
        value = wrappedValue
    }
    
    public var wrappedValue: Value {
        get {
            return value
        }

        set {
            value = newValue

            if duplicatedNotify || (value != newValue) {
                observerContainer.notify(newValue)
            }
        }
    }

    public var projectedValue: ObserverContainer {
        return observerContainer
    }
}

// MARK: - Container

public extension Observing {
    class ObserverContainer {
        public typealias ObservingType = (_ newValue: Value, _ addtionalInfo: [String: Any]?) -> Void
        private let base: Observing<Value>
        private var observers = [ObserverKey: ObservingType]()
        
        init(_ base: Observing<Value>) {
            self.base = base
        }

        @discardableResult public func addObserver(_ observer: @escaping ObservingType) -> ObserverKey {
            let key = ObserverKey.generateKey(base: base)
            observers[key] = observer
            base.nextId += 1
            
            return key
        }

        public func removeObserver(_ observerKey: ObserverKey) {
            observers[observerKey] = nil
        }

        fileprivate func notify(_ newValue: Value) {
            let notifyWorkItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }

                self.observers.values.forEach { (observer) in
                    observer(newValue, self.base.additionalInfo)
                }
            }

            guard let queue = base.notificationQueue else {
                notifyWorkItem.perform()
                return
            }
            
            queue.async(execute: notifyWorkItem)
        }
    }
    
    struct ObserverKey: Hashable {
        private let id: Int
        
        private init(id: Int) {
            self.id = id
        }
        
        fileprivate static func generateKey(base: Observing) -> ObserverKey {
            var key: ObserverKey!
            base._nextId.mutate {
                key = ObserverKey(id: $0)
                $0 += 1
            }

            return key
        }
    }
}
