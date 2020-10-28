//
//  UpstreamEventSendable+Convenience.swift
//  NuguAgents
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/10/27.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
//

import Foundation

import NuguCore

import RxSwift

extension UpstreamDataSendable {
    func sendEvent(
        _ event: Single<Eventable>,
        eventIdentifier: EventIdentifier,
        context: Single<[ContextInfo]>,
        property: CapabilityAgentProperty,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> Completable {
        return Single.zip(event, context)
            .map { (event, contextPayload) -> Upstream.Event in
                event.makeEventMessage(
                    property: property,
                    eventIdentifier: eventIdentifier,
                    contextPayload: contextPayload
                )
            }
            .do(
                onSuccess: { [weak self] in
                    self?.sendEvent($0, completion: completion)
                },
                onError: { completion?(.error($0)) }
            )
            .asCompletable()
    }
}
