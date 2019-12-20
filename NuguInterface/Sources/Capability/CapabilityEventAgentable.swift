//
//  CapabilityEventAgentable.swift
//  NuguInterface
//
//  Created by yonghoonKwon on 2019/12/19.
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

public protocol CapabilityEventAgentable: CapabilityAgentable {
    associatedtype Event: Eventable
    
    /// <#Description#>
    var upstreamDataSender: UpstreamDataSendable { get }
    
    /// <#Description#>
    /// - Parameter event: <#event description#>
    /// - Parameter contextPayload: <#contextPayload description#>
    /// - Parameter dialogRequestId: <#dialogRequestId description#>
    /// - Parameter completion: <#completion description#>
    func sendEvent(
        _ event: Event,
        contextPayload: ContextPayload,
        dialogRequestId: String,
        completion: ((Result<Data, Error>) -> Void)?
    )
}

// MARK: - Default

public extension CapabilityEventAgentable {
    /// <#Description#>
    /// - Parameter event: <#event description#>
    /// - Parameter dialogRequestId: <#dialogRequestId description#>
    /// - Parameter completion: <#completion description#>
    func sendEvent(
        _ event: Event,
        dialogRequestId: String,
        completion: ((Result<Data, Error>) -> Void)? = nil
    ) {
        let contextPayload = ContextPayload(
            supportedInterfaces: [self.contextInfoRequestContext()].compactMap({ $0 }),
            client: []
        )
        
        sendEvent(event, contextPayload: contextPayload, dialogRequestId: dialogRequestId, completion: completion)
    }
    
    /// <#Description#>
    /// - Parameter event: <#event description#>
    /// - Parameter contextPayload: <#contextPayload description#>
    /// - Parameter dialogRequestId: <#dialogRequestId description#>
    /// - Parameter completion: <#completion description#>
    func sendEvent(
        _ event: Event,
        contextPayload: ContextPayload,
        dialogRequestId: String,
        completion: ((Result<Data, Error>) -> Void)? = nil
    ) {
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
        
        upstreamDataSender.send(upstreamEventMessage: eventMessage, completion: completion)
    }
}
