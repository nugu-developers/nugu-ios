//
//  DisplayAgentProtocol.swift
//  NuguInterface
//
//  Created by MinChul Lee on 16/05/2019.
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

/// The DisplayAgent handles directives for controlling template display.
public protocol DisplayAgentProtocol:
CapabilityAgentable,
ContextInfoDelegate,
HandleDirectiveDelegate,
PlaySyncDelegate {
    var messageSender: MessageSendable! { get set }
    var playSyncManager: PlaySyncManageable! { get set }
    
    /// Adds a delegate to be notified of DisplayTemplateType changes.
    ///
    /// - Parameter delegate: The object to add.
    func add(delegate: DisplayAgentDelegate)
    
    /// Removes a delegate from DisplayAgent.
    ///
    /// - Parameter delegate: The object to remove.
    func remove(delegate: DisplayAgentDelegate)
    
    /// All of template has a playSericeId and all of element has a token.
    ///
    /// The Client should call this when element(view) selected(clicked).
    /// - Parameter templateId: The unique identifier for the template.
    /// - Parameter token: The unique identifier for the element.
    func elementDidSelect(templateId: String, token: String)
    
    /// This function notifies the DisplayAgent that a template has been cleared from the screen.
    ///
    /// This function should be called if the template is no longer exposed to the user.
    /// - Parameter template: The template removed from the screen.
    func clearDisplay(delegate: DisplayAgentDelegate)
}
