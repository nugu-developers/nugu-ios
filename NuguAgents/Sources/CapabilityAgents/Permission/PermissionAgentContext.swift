//
//  PermissionAgentContext.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2021/03/19.
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

public struct PermissionAgentContext: Codable {
    public let permissions: [Permission]
    
    public init(permissions: [Permission.Name: Permission.State]) {
        self.permissions = permissions.map { Permission(name: $0.key, state: $0.value) }
    }
    
    public struct Permission: Codable {
        public let name: Name
        public let state: State
        
        public enum Name: String, Codable {
            case location = "LOCATION"
            case call = "CALL"
            case message = "MESSAGE"
            case phonebook = "PHONEBOOK"
            case callHistory = "CALL_HISTORY"
        }
        
        public enum State: String, Codable {
            case granted = "GRANTED"
            case denied = "DENIED"
        }
    }
}
