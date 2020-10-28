//
//  SystemAgent+Event.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 10/06/2019.
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

// MARK: - Event

extension SystemAgent {    
    struct Event {
        let typeInfo: TypeInfo
        let referrerDialogRequestId: String?
        
        enum TypeInfo {
            case synchronizeState
        }
    }
}

// MARK: - Eventable

extension SystemAgent.Event: Eventable {
    var payload: [String: AnyHashable] {
        switch typeInfo {
        default:
            return [:]
        }
    }
    
    var name: String {
        switch typeInfo {
        case .synchronizeState:
            return "SynchronizeState"
        }
    }
}
