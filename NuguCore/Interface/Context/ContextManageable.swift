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
public protocol ContextManageable: class {
    /// Add ContextInfoDelegate to ContextManager
    ///
    /// When the context manager receives a getContexts request it queries the registered ContextInfoDelegate for updated context.
    /// - Parameter provideContextDelegate: The object that acts as the provider of the ContextManager
    func add(provideContextDelegate: ContextInfoDelegate)
    
    /// Remove ContextInfoDelegate from ContextManager
    /// - Parameter provideContextDelegate: The object to remove
    func remove(provideContextDelegate: ContextInfoDelegate)
    
    /// Request the ContextManager for context.
    ///
    /// Request will be sent to the ContextInfoDelegate via the contextInfoRequestContext requests.
    /// - Parameter completion: A completion handler block to execute when all of the requests are finished.
    func getContexts(completion: @escaping (ContextPayload) -> Void)
}
