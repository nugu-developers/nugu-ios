//
//  EventSender.swift
//  NuguAgents
//
//  Created by childc on 2020/02/18.
//

import Foundation

import NuguCore

extension Eventable {
    func makeEventMessage(agent: CapabilityAgentable, dialogRequestId: String? = nil, contextPayload: ContextPayload? = nil) -> UpstreamEventMessage {
        let header = UpstreamHeader(
            namespace: agent.capabilityAgentProperty.name,
            name: name,
            version: agent.capabilityAgentProperty.version,
            dialogRequestId: dialogRequestId ?? TimeUUID().hexString,
            messageId: TimeUUID().hexString
        )

        var contextPayload = contextPayload
        if contextPayload == nil {
            agent.contextInfoRequestContext { (contextInfo) in
                contextPayload = ContextPayload(
                    supportedInterfaces: [contextInfo].compactMap({ $0 }),
                    client: []
                )
            }
        }
        
        return UpstreamEventMessage(
            payload: payload,
            header: header,
            contextPayload: contextPayload!
        )
    }
}
