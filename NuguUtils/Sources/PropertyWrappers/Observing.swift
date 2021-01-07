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
    lazy var observerContainer: ObserverContainer = ObserverContainer(self)
    
    public init(wrappedValue: Value) {
        value = wrappedValue
    }
    
    public var wrappedValue: Value {
        get {
            return value
        }

        set {
            let notifyable = duplicatedNotify || (value != newValue)
            value = newValue

            if notifyable {
                observerContainer.notify(newValue)
            }
        }
    }

    public var projectedValue: ObserverContainer {
        return observerContainer
    }
    
    public var notificationQueue: DispatchQueue?
    public var additionalInfo: [String: Any]?
    public var duplicatedNotify = true

    public class ObserverContainer: ObserverContainable {
        public typealias ObservingType = (_ newValue: Value, _ addtionalInfo: [String: Any]?) -> Void
        private let base: Observing<Value>
        private var observers: [ObservingType?] = []
        
        init(_ base: Observing<Value>) {
            self.base = base
        }

        @discardableResult public func addObserver(_ observer: @escaping ObservingType) -> Int {
            let currentIdx = observers.count
            observers.append(observer)

            return currentIdx
        }

        public func removeObserver(_ observerKey: Int) {
            observers.remove(at: observerKey)
        }

        fileprivate func notify(_ newValue: Value) {
            let notifyWorkItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }

                self.observers = self.observers.compactMap { $0 }
                self.observers.forEach { (observer) in
                    observer?(newValue, self.base.additionalInfo)
                }
            }

            guard let queue = base.notificationQueue else {
                notifyWorkItem.perform()
                return
            }
            
            queue.async(execute: notifyWorkItem)
        }
    }
}

public protocol ObserverContainable {
    associatedtype ObservingType
    @discardableResult func addObserver(_ observer: ObservingType) -> Int
    func removeObserver(_ observerKey: Int)
}
