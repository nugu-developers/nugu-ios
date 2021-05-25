//
//  FocusChannelDelegate.swift
//  NuguCore
//
//  Created by MinChul Lee on 24/04/2019.
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

/// FocusChannelDelegate may be capability agent whose needs to be registered with the ContextManager.
public protocol FocusChannelDelegate: AnyObject {
    /// <#Description#>
    func focusChannelPriority() -> FocusChannelPriority
    
    /// Used to notify the observer of the Channel of focus changes. Once called, the client should make a user
    /// observable change only and return immediately.
    ///
    /// Any additional work that needs to be done should be done on a separate thread or after returning.
    /// "User observable change" here refers to events that the end user of the product can visibly see or hear.
    /// - Parameter focusState: The new Focus of the channel.
    func focusChannelDidChange(focusState: FocusState)
}
