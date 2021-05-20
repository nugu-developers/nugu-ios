//
//  MessageAgentDelegate.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/01/07.
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

/// The `MessageAgentDelegate` protocol defines methods that a delegate of a `MessageAgent` object can implement to receive directives or request context.
public protocol MessageAgentDelegate: AnyObject {
    
    /// Provide a context of `MessageAgent`.
    /// This function should return as soon as possible to reduce request delay.
    func messageAgentRequestContext() -> MessageAgentContext?
    
    /// Called method when a directive 'SendCandidates' is received.
    /// - Parameters:
    ///   - payload: The payload of `MessageAgentDirectivePayload.SendCandidates`
    ///   - header: The header of the originally handled directive.
    func messageAgentDidReceiveSendCandidates(payload: MessageAgentDirectivePayload.SendCandidates, header: Downstream.Header)
    
    /// Called method when a directive 'SendMessasge' is received.
    /// - Parameters:
    ///   - payload: The payload of `MessageAgentDirectivePayload.SendMessage`
    ///   - header: The header of the originally handled directive.
    /// - Returns: If have an error, the error-code is returned, otherwise it returns `nil`.
    func messageAgentDidReceiveSendMessage(payload: MessageAgentDirectivePayload.SendMessage, header: Downstream.Header) -> String?
}
