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

import NuguInterface

/// <#Description#>
public protocol CapabilityEventSendable {
    associatedtype Event: Eventable
    
    /// <#Description#>
    /// - Parameter event: <#event description#>
    /// - Parameter contextPayload: <#contextPayload description#>
    /// - Parameter dialogRequestId: <#dialogRequestId description#>
    /// - Parameter property: <#property description#>
    /// - Parameter upstreamDataSender: <#upstreamDataSender description#>
    /// - Parameter completion: <#completion description#>
    func sendEvent(_ event: Event,
                   contextPayload: ContextPayload,
                   dialogRequestId: String,
                   property: CapabilityAgentProperty,
                   by upstreamDataSender: UpstreamDataSendable,
                   completion: ((Result<Data, Error>) -> Void)?)
}

// MARK: - Optional

public extension CapabilityEventSendable {
    /// <#Description#>
    /// - Parameter event: <#event description#>
    /// - Parameter context: <#contexts description#>
    /// - Parameter dialogRequestId: <#dialogRequestId description#>
    /// - Parameter property: <#property description#>
    /// - Parameter upstreamDataSender: <#upstreamDataSender description#>
    /// - Parameter completion: <#completion description#>
    func sendEvent(_ event: Event,
                   context: ContextInfo?,
                   dialogRequestId: String,
                   property: CapabilityAgentProperty,
                   by upstreamDataSender: UpstreamDataSendable,
                   completion: ((Result<Data, Error>) -> Void)? = nil) {
        let contextPayload = ContextPayload(
            supportedInterfaces: context != nil ? [context!] : [],
            client: []
        )
        
        sendEvent(event, contextPayload: contextPayload, dialogRequestId: dialogRequestId, property: property, by: upstreamDataSender, completion: completion)
    }
    
    /// <#Description#>
    /// - Parameter event: <#event description#>
    /// - Parameter contextPayload: <#contextPayload description#>
    /// - Parameter dialogRequestId: <#dialogRequestId description#>
    /// - Parameter property: <#property description#>
    /// - Parameter upstreamDataSender: <#upstreamDataSender description#>
    /// - Parameter completion: <#completion description#>
    func sendEvent(_ event: Event,
                   contextPayload: ContextPayload,
                   dialogRequestId: String,
                   property: CapabilityAgentProperty,
                   by upstreamDataSender: UpstreamDataSendable,
                   completion: ((Result<Data, Error>) -> Void)? = nil) {
        let header = UpstreamHeader(
            namespace: property.name,
            name: event.name,
            version: property.version,
            dialogRequestId: dialogRequestId
        )
        
        let eventMessage = UpstreamEventMessage(
            payload: event.payload,
            header: header,
            contextPayload: contextPayload
        )
        
        upstreamDataSender.send(upstreamEventMessage: eventMessage, completion: completion)
    }
}
