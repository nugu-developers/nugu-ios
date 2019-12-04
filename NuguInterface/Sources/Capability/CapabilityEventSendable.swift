//
//  CapabilityEventSendable.swift
//  NuguInterface
//
//  Created by yonghoonKwon on 10/06/2019.
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

/// <#Description#>
public protocol CapabilityEventSendable: CapabilityConfigurable {
    associatedtype Event: Eventable
    
    /// <#Description#>
    /// - Parameter event: <#event description#>
    /// - Parameter contextPayload: <#contextPayload description#>
    /// - Parameter dialogRequestId: <#dialogRequestId description#>
    /// - Parameter messageSender: <#messageSender description#>
    func sendEvent(_ event: Event,
                   contextPayload: ContextPayload,
                   dialogRequestId: String,
                   by messageSender: MessageSendable,
                   completion: ((SendMessageStatus) -> Void)?)
}

// MARK: - Optional

public extension CapabilityEventSendable {
    /// <#Description#>
    /// - Parameter event: <#event description#>
    /// - Parameter context: <#contexts description#>
    /// - Parameter dialogRequestId: <#dialogRequestId description#>
    /// - Parameter messageSender: <#messageSender description#>
    func sendEvent(_ event: Event,
                   context: ContextInfo?,
                   dialogRequestId: String,
                   by messageSender: MessageSendable,
                   completion: ((SendMessageStatus) -> Void)? = nil) {
        let contextPayload = ContextPayload(
            supportedInterfaces: context != nil ? [context!] : [],
            client: []
        )
        
        sendEvent(event, contextPayload: contextPayload, dialogRequestId: dialogRequestId, by: messageSender, completion: completion)
    }
    
    /// <#Description#>
    /// - Parameter event: <#event description#>
    /// - Parameter contextPayload: <#contextPayload description#>
    /// - Parameter dialogRequestId: <#dialogRequestId description#>
    /// - Parameter messageSender: <#messageSender description#>
    func sendEvent(_ event: Event,
                   contextPayload: ContextPayload,
                   dialogRequestId: String,
                   by messageSender: MessageSendable,
                   completion: ((SendMessageStatus) -> Void)? = nil) {
        let header = UpstreamHeader(
            namespace: capabilityAgentProperty.name,
            name: event.name,
            version: capabilityAgentProperty.version,
            dialogRequestId: dialogRequestId
        )
        
        let eventMessage = UpstreamEventMessage(
            payload: event.payload,
            header: header,
            contextPayload: contextPayload
        )
        
        messageSender.send(upstreamEventMessage: eventMessage, completion: completion)
    }
}
