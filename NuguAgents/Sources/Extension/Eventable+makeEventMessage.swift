//
//  Eventable+makeEventMessage.swift
//  NuguAgents
//
//  Created by childc on 2020/02/18.
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

public extension Eventable {
    func makeEventMessage(
        property: CapabilityAgentProperty,
        eventIdentifier: EventIdentifier,
        httpHeaderFields: [String: String]? = nil,
        contextPayload: [ContextInfo]
    ) -> Upstream.Event {
        let header = Upstream.Header(
            namespace: property.name,
            name: name,
            version: property.version,
            dialogRequestId: eventIdentifier.dialogRequestId,
            messageId: eventIdentifier.messageId,
            referrerDialogRequestId: referrerDialogRequestId
        )
        
        return Upstream.Event(payload: payload, header: header, httpHeaderFields: httpHeaderFields, contextPayload: contextPayload)
    }
}
