//
//  Atomic.swift
//  SilverTray
//
//  Created by childc on 2020/09/02.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

final class Atomic<Value> {
    private let queue = DispatchQueue(label: "com.sktelecom.silver_tray.atomic.queue")
    var value: Value
    
    init(_ value: Value) {
        self.value = value
    }
    
    var atomicValue: Value {
        get { queue.sync { value } }
        set { queue.sync { value = newValue } }
    }

    func atomicMutate(_ transform: (inout Value) -> Void) {
        queue.sync {
            transform(&value)
        }
    }
}
