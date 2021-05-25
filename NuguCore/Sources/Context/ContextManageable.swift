//
//  ContextManageable.swift
//  NuguCore
//
//  Created by MinChul Lee on 25/04/2019.
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

/// Manage capability agent's context.
/// Context is a container used to communicate the state of the capability agents to server.
public protocol ContextManageable: AnyObject {
    /// Add `ContextInfoProvidable` to `ContextManager`
    ///
    /// When the context manager receives a getContexts request it queries the registered `ContextInfoProvidable` for updated context.
    /// - Parameter provider: The object that acts as the provider of the ContextManager
    func addProvider(_ provider: @escaping ContextInfoProviderType)
    
    /// Remove `ContextInfoProvidable` from `ContextManager`
    /// - Parameter provider: The object to remove
    func removeProvider(_ provider: @escaping ContextInfoProviderType)
    
    /// Request the `ContextManager` for context.
    ///
    /// Request will be sent to the `ContextInfoDelegate` via the `contextInfoRequestContext` requests.
    /// - Parameter completion: A completion handler block to execute when all of the requests are finished.
    func getContexts(completion: @escaping ([ContextInfo]) -> Void)
    
    /// Request the `ContextManager` for context.
    ///
    /// Request will be sent to the `ContextInfoDelegate` via the `contextInfoRequestContext` requests.
    /// `[ContextInfo]` includes only version information.(Except `namespace`'s `ContextInfo`).
    /// - Parameter namespace: May be `CapabilityAgentCategory.name`.
    /// - Parameter completion: A completion handler block to execute when all of the requests are finished.
    func getContexts(namespace: String, completion: @escaping ([ContextInfo]) -> Void)
}
