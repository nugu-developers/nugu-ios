//
//  MessengerAgentDelegate.swift
//  NuguMessengerAgent
//
//  Created by yonghoonKwon on 2021/04/13.
//  Copyright (c) 2021 SK Telecom Co., Ltd. All rights reserved.
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

public protocol MessengerAgentDelegate: AnyObject {
    /// <#Description#>
    func messengerAgentRequestContext() -> MessengerAgentContext?
    
    /// <#Description#>
    func messengerAgentDidReceiveCreateSucceeded(
        payload: MessengerAgentDirectivePayload.CreateSucceeded,
        header: Downstream.Header
    )
    
    /// <#Description#>
    func messengerAgentDidReceiveConfigure(
        payload: MessengerAgentDirectivePayload.Configure,
        header: Downstream.Header
    )
    
    /// <#Description#>
    func messengerAgentDidReceiveSendHistory(
        payload: MessengerAgentDirectivePayload.SendHistory,
        header: Downstream.Header
    )
    
    /// <#Description#>
    func messengerAgentDidReceiveNotifyMessage(
        payload: MessengerAgentDirectivePayload.NotifyMessage,
        header: Downstream.Header
    )
    
    /// <#Description#>
    func messengerAgentDidReceiveNotifyStartDialog(
        payload: MessengerAgentDirectivePayload.NotifyStartDialog,
        header: Downstream.Header
    )
    
    /// <#Description#>
    func messengerAgentDidReceiveNotifyStopDialog(
        payload: MessengerAgentDirectivePayload.NotifyStopDialog,
        header: Downstream.Header
    )
    
    /// <#Description#>
    func messengerAgentDidReceiveNotifyRead(
        payload: MessengerAgentDirectivePayload.NotifyRead,
        header: Downstream.Header
    )
    
    /// <#Description#>
    func messengerAgentDidReceiveNotifyReaction(
        payload: MessengerAgentDirectivePayload.NotifyReaction,
        header: Downstream.Header
    )
    
    /// <#Description#>
    func messengerAgentDidReceiveMessageRedirect(
        payload: MessengerAgentDirectivePayload.MessageRedirect,
        header: Downstream.Header
    )
}
