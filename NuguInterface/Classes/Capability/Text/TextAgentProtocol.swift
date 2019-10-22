//
//  TextAgentProtocol.swift
//  NuguInterface
//
//  Created by yonghoonKwon on 17/06/2019.
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

/// Text-agent is needed to send event-based text recognition.
public protocol TextAgentProtocol:
CapabilityAgentable,
ProvideContextDelegate,
FocusChannelDelegate,
ReceiveMessageDelegate {
    var contextManager: ContextManageable! { get set }
    var messageSender: MessageSendable! { get set }
    var focusManager: FocusManageable! { get set }
    var channel: FocusChannelConfigurable! { get set }
    var dialogStateAggregator: DialogStateAggregatable! { get set }
    
    /// Adds a delegate to be notified of `TextAgentState` and `TextAgentResult` changes.
    /// - Parameter delegate: The delegate object to add.
    func add(delegate: TextAgentDelegate)
    
    /// Removes a delegate from `TextAgent`.
    /// - Parameter delegate: The delegate object to remove.
    func remove(delegate: TextAgentDelegate)
    
    /// Send event that needs a text-based recognition
    /// - Parameter text: The `text` to be recognized
    func requestTextInput(text: String)
}
