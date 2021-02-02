//
//  PhoneCallAgentDelegate.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/05/12.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

/// The `PhoneCallAgentDelegate` protocol defines methods that a delegate of a `PhoneCallAgent` object can implement to receive directives or request context.
public protocol PhoneCallAgentDelegate: class {
    
    /// Provide a context of `PhoneCallAgent`.
    ///
    /// This function should return as soon as possible to reduce request delay.
    /// - Returns: The context for `PhoneCallAgent`
    func phoneCallAgentRequestContext() -> PhoneCallContext
    
    /// Called method when a directive 'SendCandidates' is received.
    /// - Parameters:
    ///   - item: The item of `PhoneCallCandidatesItem`
    ///   - header: The header of the originally handled directive.
    func phoneCallAgentDidReceiveSendCandidates(item: PhoneCallCandidatesItem, header: Downstream.Header)
    
    /// Called method when a directive 'MakeCall' is received.
    /// - Parameters:
    ///   - callType: Types of phone calls
    ///   - recipient: An contact about the recipient(callee)
    ///   - header: The header of the originally handled directive.
    /// - Returns: If have an error, the error-code is returned, otherwise it returns `nil`.
    func phoneCallAgentDidReceiveMakeCall(callType: PhoneCallType, recipient: PhoneCallPerson, header: Downstream.Header) -> PhoneCallErrorCode?
}
