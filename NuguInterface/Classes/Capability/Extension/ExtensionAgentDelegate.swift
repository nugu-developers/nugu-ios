//
//  ExtensionAgentDelegate.swift
//  NuguInterface
//
//  Created by yonghoonKwon on 25/07/2019.
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

/// The `ExtensionAgentDelegate` protocol defines methods that action when `ExtensionAgent` receives a directive.
///
/// The methods of this protocol are all mandatory.
public protocol ExtensionAgentDelegate: class {
    /// Tells the delegate that `ExtensionAgent` received `action` directive
    ///
    /// When received any data, must call completion block to send an event.
    /// - Parameter data: The message decoded from json to dictionary received by `action` directive
    /// - Parameter playServiceId: The unique identifier to specify play service.
    /// - Parameter completion: A block to call when you are finished performing the action
    func extensionAgentDidReceive(data: [String: Any], playServiceId: String, completion: @escaping (Bool) -> Void)
}
