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

/// The `DisplayAgent` delegate is used to notify observers when a template directive is received.
public protocol DisplayAgentDelegate: class {
    /// Tells the delegate that the specified template should be displayed.
    ///
    /// - Parameter template: The template to display.
    func displayAgentShouldRender(template: DisplayTemplate, completion: @escaping (AnyObject?) -> Void)
    
    /// Tells the delegate that the specified template should be removed from the screen.
    ///
    /// - Parameter token: The template token to remove from the screen.
    func displayAgentDidClear(token: String)
    
    /// Tells the delegate that the displayed template should move focus with given direction.
    /// - Parameter token: The template token to move focus.
    /// - Parameter direction: Direction to move focus.
    /// - Parameter completion: Whether succeeded or not.
    func displayAgentShouldMoveFocus(token: String, direction: DisplayControlPayload.Direction, completion: @escaping (Bool) -> Void)
    
    /// Tells the delegate that the displayed template should scroll with given direction.
    /// - Parameter token: The template token to scroll.
    /// - Parameter direction: Direction to scroll.
    /// - Parameter completion: Whether succeeded or not.
    func displayAgentShouldScroll(token: String, direction: DisplayControlPayload.Direction, completion: @escaping (Bool) -> Void)
    
    /// Provide a context of display-agent.
    /// - Parameter token: The template token to send context.
    func displayAgentRequestContext(token: String, completion: @escaping (DisplayContext?) -> Void)
    
    /// Should update proper displaying view with given template.
    func displayAgentShouldUpdate(token: String, template: DisplayTemplate)
}
