//
//  ExtensionAgent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 25/07/2019.
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

import NuguCore

import RxSwift

public final class ExtensionAgent: ExtensionAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .extension, version: "1.1")
    
    // ExtensionAgentProtocol
    public weak var delegate: ExtensionAgentDelegate?
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    // Handleable Directive
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Action", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleAction)
    ]
    
    private var disposeBag = DisposeBag()
    
    public init(
        upstreamDataSender: UpstreamDataSendable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        self.upstreamDataSender = upstreamDataSender
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        
        contextManager.add(delegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - ExtensionAgentProtocol

public extension ExtensionAgent {
    @discardableResult func requestCommand(data: [String: AnyHashable], playServiceId: String, completion: ((StreamDataState) -> Void)?) -> String {
        return sendCompactContextEvent(
            Event(playServiceId: playServiceId, typeInfo: .commandIssued(data: data)).rx,
            completion: completion
        ).dialogRequestId
    }
}

// MARK: - ContextInfoDelegate

extension ExtensionAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: (ContextInfo?) -> Void) {
        let payload: [String: AnyHashable?] = [
            "version": capabilityAgentProperty.version,
            "data": delegate?.extensionAgentRequestContext()
        ]
        
        completion(
            ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 })
        )
    }
}

// MARK: - Private(Directive)

private extension ExtensionAgent {
    func handleAction() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let item = try? JSONDecoder().decode(ExtensionAgentItem.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }

            self?.delegate?.extensionAgentDidReceiveAction(
                data: item.data,
                playServiceId: item.playServiceId,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (isSuccess) in
                    guard let self = self else { return }
                    
                    let typeInfo: Event.TypeInfo = isSuccess ? .actionSucceeded(referrerDialogRequestId: directive.header.dialogRequestId) : .actionFailed(referrerDialogRequestId: directive.header.dialogRequestId)
                    self.sendCompactContextEvent(
                        Event(playServiceId: item.playServiceId, typeInfo: typeInfo).rx
                    )
            })
        }
    }
}

// MARK: - Private (Event)

private extension ExtensionAgent {
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
