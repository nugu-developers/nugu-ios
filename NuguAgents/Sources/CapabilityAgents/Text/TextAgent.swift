//
//  TextAgent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 17/06/2019.
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

public final class TextAgent: TextAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .text, version: "1.7")
    public weak var delegate: TextAgentDelegate?
    
    // Private
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    private let directiveSequencer: DirectiveSequenceable
    private let dialogAttributeStore: DialogAttributeStoreable
    private let interactionControlManager: InteractionControlManageable
    private let textDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.text_agent", qos: .userInitiated)
    
    private var currentInteractionControl: InteractionControl?
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(
            namespace: capabilityAgentProperty.name,
            name: "TextSource",
            blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false),
            directiveHandler: handleTextSource
        ),
        DirectiveHandleInfo(
            namespace: capabilityAgentProperty.name,
            name: "TextRedirect",
            blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false),
            directiveHandler: handleTextRedirect
        ),
        DirectiveHandleInfo(
            namespace: capabilityAgentProperty.name,
            name: "ExpectTyping",
            blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false),
            directiveHandler: handleExpectTyping
        )
    ]
    
    private var disposeBag = DisposeBag()
    private var expectTyping: TextAgentExpectTyping? {
        didSet {
            guard oldValue?.dialogRequestId != expectTyping?.dialogRequestId else { return }
            log.debug("expectTyping is changed from:\(oldValue?.dialogRequestId ?? "nil") to:\(expectTyping?.dialogRequestId ?? "nil")")
            
            // TextAgent의 ExpectTyping은 함꼐 내려온 template에 종속적으로 동작해야 해서 messasgeId 대신 dialogRequestId를 사용한다.
            if let oldDialogRequestId = oldValue?.dialogRequestId {
                // Remove last attributes
                dialogAttributeStore.removeAttributes(key: oldDialogRequestId)
            }
            
            if let dialogRequestId = expectTyping?.dialogRequestId,
               let payload = expectTyping?.payload.dictionary {
                // Store attributes
                dialogAttributeStore.setAttributes(payload.compactMapValues { $0 }, key: dialogRequestId)
            }
        }
    }
    
    public init(
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable,
        directiveSequencer: DirectiveSequenceable,
        dialogAttributeStore: DialogAttributeStoreable,
        interactionControlManager: InteractionControlManageable
    ) {
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
        self.directiveSequencer = directiveSequencer
        self.dialogAttributeStore = dialogAttributeStore
        self.interactionControlManager = interactionControlManager
        
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        contextManager.addProvider(contextInfoProvider)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        contextManager.removeProvider(contextInfoProvider)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        let payload: [String: AnyHashable] = ["version": self.capabilityAgentProperty.version]
        completion(ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload))
    }
}

// MARK: - TextAgentProtocol

extension TextAgent {
    @discardableResult public func requestTextInput(
        text: String,
        token: String?,
        source: TextInputSource?,
        requestType: TextAgentRequestType,
        completion: ((StreamDataState) -> Void)?
    ) -> String {
        sendFullContextEvent(
            textInput(
                text: text,
                token: token,
                source: source,
                requestType: requestType
            ),
            completion: completion
        )
        .dialogRequestId
    }
}

// MARK: - ContextInfoDelegate

extension TextAgent: ContextInfoProvidable {
    public func requestContextInfo(completion: (ContextInfo?) -> Void) {
        let payload: [String: AnyHashable] = ["version": capabilityAgentProperty.version]
        completion(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload))
    }
}

// MARK: - Private(Directive)

private extension TextAgent {
    func handleTextSource() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payload = try? JSONDecoder().decode(TextAgentSourceItem.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            
            self?.textDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard self.delegate?.textAgentShouldHandleTextSource(directive: directive) != false else {
                    self.sendCompactContextEvent(Event(
                        typeInfo: .textSourceFailed(token: payload.token, playServiceId: payload.playServiceId, errorCode: "NOT_SUPPORTED_STATE"),
                        referrerDialogRequestId: directive.header.dialogRequestId
                    ).rx)
                    return
                }
                
                let requestType: TextAgentRequestType
                if let playServiceId = payload.playServiceId {
                    requestType = .specific(playServiceId: playServiceId)
                } else {
                    requestType = .dialog
                }
                
                self.sendFullContextEvent(self.textInput(
                    text: payload.text,
                    token: payload.token,
                    requestType: requestType,
                    referrerDialogRequestId: directive.header.dialogRequestId
                ))
            }
        }
    }
    
    func handleTextRedirect() -> HandleDirective {
        return { [weak self] directive, completion in
            self?.textDispatchQueue.async { [weak self] in
                guard let self = self else {
                    completion(.canceled)
                    return
                }
                
                guard let payload = try? JSONDecoder().decode(TextAgentRedirectPayload.self, from: directive.payload) else {
                    completion(.failed("Invalid payload"))
                    return
                }
                defer { completion(.finished) }
                
                if let interactionControl = payload.interactionControl {
                    self.currentInteractionControl = interactionControl
                    self.interactionControlManager.start(mode: interactionControl.mode, category: self.capabilityAgentProperty.category)
                }
                
                let interactionHandler = { [weak self] (state: StreamDataState) in
                    guard let self = self else { return }
                    
                    switch state {
                    case .finished, .error:
                        self.currentInteractionControl = nil
                        
                        if let interactionControl = payload.interactionControl {
                            self.interactionControlManager.finish(mode: interactionControl.mode, category: self.capabilityAgentProperty.category)
                        }
                    default:
                        break
                    }
                }
                
                guard self.delegate?.textAgentShouldHandleTextRedirect(directive: directive) != false else {
                    self.sendCompactContextEvent(Event(
                        typeInfo: .textRedirectFailed(
                            token: payload.token,
                            playServiceId: payload.playServiceId,
                            errorCode: "NOT_SUPPORTED_STATE",
                            interactionControl: self.currentInteractionControl
                        ),
                        referrerDialogRequestId: directive.header.dialogRequestId
                    ).rx, completion: interactionHandler)
                    return
                }
                
                let requestType: TextAgentRequestType
                if let playServiceId = payload.targetPlayServiceId {
                    requestType = .specific(playServiceId: playServiceId)
                } else {
                    requestType = .normal
                }
                
                self.sendFullContextEvent(self.textInput(
                    text: payload.text,
                    token: payload.token,
                    requestType: requestType,
                    referrerDialogRequestId: directive.header.dialogRequestId
                ), completion: interactionHandler)
            }
        }
    }
    
    func handleExpectTyping() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion(.finished) }
            self?.expectTyping = nil
            
            if self?.delegate?.textAgentShouldTyping(directive: directive) == true {
                guard let payload = try? JSONDecoder().decode(TextAgentExpectTyping.Payload.self, from: directive.payload) else { return }
                
                self?.textDispatchQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.expectTyping = TextAgentExpectTyping(
                        messageId: directive.header.messageId,
                        dialogRequestId: directive.header.dialogRequestId,
                        payload: payload
                    )
                }
            }
        }
    }
}

// MARK: - Private(Event)

private extension TextAgent {
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
    
    @discardableResult func sendFullContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(),
            property: self.capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
}

// MARK: - Private(Eventable)

private extension TextAgent {
    func textInput(
        text: String,
        token: String?,
        source: TextInputSource? = nil,
        requestType: TextAgentRequestType,
        referrerDialogRequestId: String? = nil
    ) -> Single<Eventable> {
        return Single<[String: AnyHashable]>.create { [weak self] single in
            let disposable = Disposables.create()
            guard let self = self else { return disposable }
            
            self.textDispatchQueue.async { [weak self] in
                var attributes: [String: AnyHashable] {
                    if case let .specific(playServiceId) = requestType {
                        return ["playServiceId": playServiceId]
                    }
                    
                    var attributes = [String: AnyHashable]()
                    if case .dialog = requestType,
                       let expectTypingDialogRequestId = self?.expectTyping?.dialogRequestId,
                       let expectTypingAttribute = self?.dialogAttributeStore.requestAttributes(key: expectTypingDialogRequestId) {
                        attributes.merge(expectTypingAttribute)
                    }
                    
                    if let source = source {
                        attributes["source"] = source.description
                    }
                    
                    if let interactionControl = self?.currentInteractionControl,
                       let interactionControlData = try? JSONEncoder().encode(interactionControl),
                       let interactionControlDictionary = try? JSONSerialization.jsonObject(with: interactionControlData, options: []) as? [String: AnyHashable] {
                        attributes["interactionControl"] = interactionControlDictionary
                    }
                    
                    return attributes
                }
                
                single(.success(attributes))
            }
            
            return disposable
        }
        .flatMap { attributes in
            Event(
                typeInfo: .textInput(text: text, token: token, attributes: attributes),
                referrerDialogRequestId: referrerDialogRequestId
            ).rx
        }
    }
}

// MARK: - TextAgentExpectTyping Decorator

private extension TextAgentExpectTyping.Payload {
    var dictionary: [String: AnyHashable?] {
        return [
            "asrContext": asrContext,
            "domainTypes": domainTypes,
            "playServiceId": playServiceId
        ]
    }
}
