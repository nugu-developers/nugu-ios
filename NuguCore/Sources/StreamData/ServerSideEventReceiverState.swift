//
//  ServerSideEventReceiverState.swift
//  NuguCore
//
//  Created by childc on 2020/03/10.
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

enum ServerSideEventReceiverState: Equatable {
    case connected
    /// Connection closed.
    /// - Parameter error: If Connection closed because of the error.
    case disconnected(error: Error? = nil)
    
    static func == (lhs: ServerSideEventReceiverState, rhs: ServerSideEventReceiverState) -> Bool {
        switch (lhs, rhs) {
        case (.connected, .connected):
            return true

        case (.disconnected(let lhsError), .disconnected(let rhsError)):
            return (lhsError as NSError?)?.code == (rhsError as NSError?)?.code

        default:
            return false
        }
    }
}
