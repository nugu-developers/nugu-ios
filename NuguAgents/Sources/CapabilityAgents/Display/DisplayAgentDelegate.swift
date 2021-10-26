//
//  DisplayAgentDelegate.swift
//  NuguAgents
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

import NuguCore

public typealias HistoryControl = DisplayHistoryControl.HistoryControl

/// The `DisplayAgentDelegate`  is used to notify observers when a template directive is received.
public protocol DisplayAgentDelegate: AnyObject {
    /// Tells the delegate that the specified template should be displayed.
    ///
    /// - Parameter template: The template to display.
    func displayAgentShouldRender(template: DisplayTemplate, historyControl: HistoryControl?, completion: @escaping (AnyObject?) -> Void)
    
    /// Tells the delegate that the specified template should be removed from the screen.
    ///
    /// - Parameter templateId: The template id to remove from the screen.
    func displayAgentDidClear(templateId: String)
    
    /// Tells the delegate that the displayed template should move focus with given direction.
    /// - Parameter templateId: The template id to move focus.
    /// - Parameter direction: Direction to move focus.
    /// - Parameter header: The header of the originally handled directive.
    /// - Parameter completion: Whether succeeded or not.
    func displayAgentShouldMoveFocus(templateId: String, direction: DisplayControlPayload.Direction, header: Downstream.Header, completion: @escaping (Bool) -> Void)
    
    /// Tells the delegate that the displayed template should scroll with given direction.
    /// - Parameter templateId: The template id to scroll.
    /// - Parameter direction: Direction to scroll.
    /// - Parameter header: The header of the originally handled directive.
    /// - Parameter completion: Whether succeeded or not.
    func displayAgentShouldScroll(templateId: String, direction: DisplayControlPayload.Direction, header: Downstream.Header, completion: @escaping (Bool) -> Void)
    
    /// Provide a context of display-agent.
    /// - Parameter templateId: The template id to send context.
    func displayAgentRequestContext(templateId: String, completion: @escaping (DisplayContext?) -> Void)
    
    /// Should update proper displaying view with given template.
    /// - Parameters:
    ///   - templateId: The template id to update.
    ///   - template: The template to update.
    func displayAgentShouldUpdate(templateId: String, template: DisplayTemplate)
}
