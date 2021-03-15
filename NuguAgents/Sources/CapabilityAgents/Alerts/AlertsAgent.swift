//
//  AlertsAgent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/02/26.
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

import Foundation

import NuguCore

import RxSwift

public class AlertsAgent: AlertsAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = .init(category: .alerts, version: "1.1")
    
    // AlertsAgentProtocol
    public weak var delegate: AlertsAgentDelegate?
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    private var disposeBag = DisposeBag()
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos: [DirectiveHandleInfo] = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SetAlert", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSetAlert),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "DeleteAlerts", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleDeleteAlerts),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "DeliveryAlertAsset", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleDeliveryAlertAsset),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SetSnooze", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSetSnooze)
    ]
    
    public init(
        directiveSequencer: DirectiveSequenceable,
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable
    ) {
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
        
        contextManager.addProvider(contextInfoProvider)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        var payload = [String: AnyHashable?]()
        
        payload["version"] = self.capabilityAgentProperty.version
        
        completion(
            ContextInfo(
                contextType: .capability,
                name: self.capabilityAgentProperty.name,
                payload: payload.compactMapValues { $0 }
            )
        )
    }
}

// MARK: - AlertsAgentProtocol

public extension AlertsAgent {
    // TODO: - 검토필요
    @discardableResult func requestAlertAssetRequired(
        playServiceId: String,
        token: String,
        completion: ((StreamDataState) -> Void)?
    ) -> String {
        let event = Event(
            typeInfo: .alertAssetRequired(token: token),
            playServiceId: playServiceId
        )
        
        return sendCompactContextEvent(event.rx).dialogRequestId
    }
}

// MARK: - Private(Directive)

private extension AlertsAgent {
    func handleSetAlert() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
            
            guard let payloadDictionary = directive.payloadDictionary else {
                completion(.failed("Invalid payload"))
                return
            }
            
            guard let payloadData = try? JSONSerialization.data(withJSONObject: payloadDictionary, options: []),
                  let setAlertItem = try? JSONDecoder().decode(AlertsAgentDirectivePayload.SetAlert.self, from: payloadData) else {
                    completion(.failed("Invalid setAlertItem in payload"))
                    return
            }
            
            let isSuccess = self.delegate?.alertsAgentDidReceiveSetAlert(item: setAlertItem, header: directive.header)
            let event: Event
            
            if isSuccess == true {
                event = Event(
                    typeInfo: .setAlertSucceeded(token: setAlertItem.token),
                    playServiceId: setAlertItem.playServiceId
                )
            } else {
                event = Event(
                    typeInfo: .setAlertFailed(token: setAlertItem.token),
                    playServiceId: setAlertItem.playServiceId
                )
            }
            
            self.sendCompactContextEvent(event.rx)
        }
    }
    
    func handleDeleteAlerts() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
            
            guard let payloadDictionary = directive.payloadDictionary else {
                completion(.failed("Invalid payload"))
                return
            }
            
            guard let payloadData = try? JSONSerialization.data(withJSONObject: payloadDictionary, options: []),
                  let deleteAlertItem = try? JSONDecoder().decode(AlertsAgentDirectivePayload.DeleteAlerts.self, from: payloadData) else {
                    completion(.failed("Invalid deleteAlertItem in payload"))
                    return
            }
            
            let isSuccess = self.delegate?.alertsAgentDidReceiveDeleteAlerts(item: deleteAlertItem, header: directive.header)
            let event: Event
            
            if isSuccess == true {
                event = Event(
                    typeInfo: .deleteAlertsSucceeded(tokens: deleteAlertItem.tokens),
                    playServiceId: deleteAlertItem.playServiceId
                )
            } else {
                event = Event(
                    typeInfo: .deleteAlertsFailed(tokens: deleteAlertItem.tokens),
                    playServiceId: deleteAlertItem.playServiceId
                )
            }
            
            self.sendCompactContextEvent(event.rx)
        }
    }
    
    // TODO: - 검토필요
    func handleDeliveryAlertAsset() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
            
            guard let payloadDictionary = directive.payloadDictionary else {
                completion(.failed("Invalid payload"))
                return
            }
            
            guard let payloadData = try? JSONSerialization.data(withJSONObject: payloadDictionary, options: []),
                  let deliveryAssetItem = try? JSONDecoder().decode(AlertsAgentDirectivePayload.DeliveryAlertAsset.self, from: payloadData) else {
                    completion(.failed("Invalid deliveryAssetItem in payload"))
                    return
            }
            
            self.delegate?.alertsAgentDidReceiveDeliveryAlertAsset(item: deliveryAssetItem, header: directive.header)
        }
    }
    
    func handleSetSnooze() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
            
            guard let payloadDictionary = directive.payloadDictionary else {
                completion(.failed("Invalid payload"))
                return
            }
            
            guard let payloadData = try? JSONSerialization.data(withJSONObject: payloadDictionary, options: []),
                  let setSnoozeItem = try? JSONDecoder().decode(AlertsAgentDirectivePayload.SetSnooze.self, from: payloadData) else {
                    completion(.failed("Invalid setSnoozeItem in payload"))
                    return
            }
            
            let isSuccess = self.delegate?.alertsAgentDidReceiveSetSnooze(item: setSnoozeItem, header: directive.header)
            let event: Event
            
            if isSuccess == true {
                event = Event(
                    typeInfo: .setSnoozeSucceeded(token: setSnoozeItem.token),
                    playServiceId: setSnoozeItem.playServiceId
                )
            } else {
                event = Event(
                    typeInfo: .setSnoozeFailed(token: setSnoozeItem.token),
                    playServiceId: setSnoozeItem.playServiceId
                )
            }
            
            self.sendCompactContextEvent(event.rx)
        }
    }
}

// MARK: - Private (Event)

private extension AlertsAgent {
    @discardableResult func sendCompactContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(namespace: self.capabilityAgentProperty.name),
            property: self.capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
}
