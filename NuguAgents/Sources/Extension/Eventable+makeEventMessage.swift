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

extension Eventable {
    func makeEventMessage(agent: CapabilityAgentable, dialogRequestId: String? = nil, referrerDialogRequestId: String? = nil, contextPayload: ContextPayload? = nil) -> Upstream.Event {
        let header = Upstream.Event.Header(
            namespace: agent.capabilityAgentProperty.name,
            name: name,
            version: agent.capabilityAgentProperty.version,
            dialogRequestId: dialogRequestId ?? TimeUUID().hexString,
            messageId: TimeUUID().hexString,
            referrerDialogRequestId: referrerDialogRequestId
        )

        // TODO: async로 변경 예정임.
        var contextPayload = contextPayload
        if contextPayload == nil {
            agent.contextInfoRequestContext { (contextInfo) in
                contextPayload = ContextPayload(
                    supportedInterfaces: [contextInfo].compactMap({ $0 }),
                    client: []
                )
            }
        }
        
        return Upstream.Event(
            payload: payload,
            header: header,
            contextPayload: contextPayload!
        )
    }
}
