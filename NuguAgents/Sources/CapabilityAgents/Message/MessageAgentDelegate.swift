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

/// <#Description#>
public protocol MessageAgentDelegate: class {
    /// <#Description#>
    func messageAgentRequestContext() -> MessageAgentContext?
    
    /// <#Description#>
    /// - Parameters:
    ///   - item: <#item description#>
    ///   - header: <#header description#>
    func messageAgentDidReceiveSendCandidates(item: MessageCandidatesItem, header: Downstream.Header)
    
    /// <#Description#>
    /// - Parameters:
    ///   - recipient: <#recipient description#>
    ///   - header: <#header description#>
    /// - Returns: If have an error, the error-code is returned, otherwise it returns `nil`.
    func messageAgentDidReceiveSendMessage(recipient: MessageAgentContact, header: Downstream.Header) -> String?
}
