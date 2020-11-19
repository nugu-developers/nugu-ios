//
//  Publish.swift
//  NuguUtils
//
//  Created by childc on 2019/11/18.
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

import RxSwift

@propertyWrapper
public struct Publish<Value> {
    private var value: Value
    private let subject = PublishSubject<Value>()
    
    public init(wrappedValue value: Value) {
        self.value = value
    }
    
    public var wrappedValue: Value {
        get {
            return value
        }
        
        set {
            value = newValue
            subject.onNext(value)
        }
    }
    
    /// The property that can be accessed with the `$` syntax and allows access to the `Publish`
    public var projectedValue: Observable<Value> {
        return subject.asObserver()
    }
}
