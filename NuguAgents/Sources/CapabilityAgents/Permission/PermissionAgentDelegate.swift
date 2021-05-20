//
//  PermissionAgentDelegate.swift
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

import NuguCore

/// The `PermissionAgentDelegate` protocol defines methods that a delegate of a `PermissionAgent` object can implement to receive directives or request context.
public protocol PermissionAgentDelegate: AnyObject {
    /// Provide a context of `PermissionAgent`.
    /// This function should return as soon as possible to reduce request delay.
    func permissionAgentRequestContext() -> PermissionAgentContext
    
    /// Called method when a directive 'RequestPermission' is received.
    /// - Parameters:
    ///   - payload: The requested permission information.
    ///   - header: The header of the originally handled directive.
    func permissionAgentDidReceiveRequestPermission(payload: PermissionAgentDirectivePayload.RequestPermission, header: Downstream.Header)
}
