//
//  TextAgentDelegate.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2019/07/19.
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

/// The `TextAgentDelegate` protocol defines method that changed state or received result.
///
/// The methods of this protocol are all optional.
public protocol TextAgentDelegate: AnyObject {
    /// Tells the delegate that `TextAgent` received result.
    /// - Parameter directive: The directive of `Text.TextSource`.
    /// - Returns: true if handled, otherwise return false
    func textAgentShouldHandleTextSource(directive: Downstream.Directive) -> Bool
    
    /// Tells the delegate that `TextAgent` received result.
    /// - Parameter directive: The directive of `Text.TextRedirect`.
    /// - Returns: true if handled, otherwise return false
    func textAgentShouldHandleTextRedirect(directive: Downstream.Directive) -> Bool
    
    /// Tells the delegate that `TextAgent` received result.
    /// - Parameter directive: The directive of `Text.ExpectTyping`.
    func textAgentShouldTyping(directive: Downstream.Directive) -> Bool
}
