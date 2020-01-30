//
//  DispatchQueue+Precondition.swift
//  NuguAgents
//
//  Created by childc on 2020/01/23.
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

enum DispatchQueuePredicate {
    case onQueue
    case onQueueAsBarrier
    case notOnQueue
}

extension DispatchQueue {
    /**
     Check the current task is running on suitalbe queue If it Built for debug.
     
     __dispatch_assert_queue() is not for common.  And precondition() is able to check though it built for release.
     - parameter condition: DispatchQueuePredicate
     */
    func precondition(_ condition: DispatchQueuePredicate) {
        #if DEBUG
        var dispatchPredicate: DispatchPredicate {
            switch condition {
            case .onQueue:
                return .onQueue(self)
            case .onQueueAsBarrier:
                return .onQueueAsBarrier(self)
            case .notOnQueue:
                return .notOnQueue(self)
            }
        }
        
        dispatchPrecondition(condition: dispatchPredicate)
        #endif
    }
}
