//
//  ImageAgent.swift
//  NuguAgents
//
//  Created by jayceSub on 2023/05/10.
//  Copyright (c) 2023 SK Telecom Co., Ltd. All rights reserved.
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

public class ImageAgent: ImageAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = .init(category: .image, version: "1.0")
    
    // private
    
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    // Handleable Directive
    
    private lazy var handleableDirectiveInfos: [DirectiveHandleInfo] = [
    ]
    
    private lazy var disposeBag = DisposeBag()
    
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
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        let payload: [String: AnyHashable] = ["version": self.capabilityAgentProperty.version]
        completion(ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload))
    }
}

// MARK: - Events

public extension ImageAgent {
    @discardableResult func requestSendImage(
        _ image: Data,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        let eventIdentifier = EventIdentifier()
        contextManager.getContexts { [weak self] contextPayload in
            guard let self = self else { return }
            self.upstreamDataSender.sendStream(
                Event(
                    typeInfo: .sendImage,
                    referrerDialogRequestId: nil
                ).makeEventMessage(
                    property: self.capabilityAgentProperty,
                    eventIdentifier: eventIdentifier,
                    contextPayload: contextPayload
                ),
                completion: nil
            )
            
            self.upstreamDataSender.sendStream(
                Attachment(typeInfo: .sendImage)
                    .makeAttachmentImage(
                        property: self.capabilityAgentProperty,
                        eventIdentifier: eventIdentifier,
                        attachmentSeq: 0,
                        isEnd: true,
                        imageData: image
                    ),
                completion: completion
            )
        }
        
        return eventIdentifier.dialogRequestId
    }
}

// MARK: - Private(Directive)

private extension ImageAgent {
}

// MARK: - Private(Event)

private extension ImageAgent {
    @discardableResult func sendCompactContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(namespace: self.capabilityAgentProperty.name),
            property: capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
}
