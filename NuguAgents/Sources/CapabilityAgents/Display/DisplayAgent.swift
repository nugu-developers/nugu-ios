//
//  DisplayAgent.swift
//  NuguAgents
//
//  Created by MinChul Lee on 16/05/2019.
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

public final class DisplayAgent: DisplayAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .display, version: "1.5")
    
    public weak var delegate: DisplayAgentDelegate?
    public var defaultDisplayTempalteDuration: DisplayTemplateDuration = .short
    
    // Private
    private let playSyncManager: PlaySyncManageable
    private let contextManager: ContextManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    private let sessionManager: SessionManageable
    private let focusManager: FocusManageable
    
    private let displayDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.display_agent", qos: .userInitiated)
    private lazy var displayScheduler = SerialDispatchQueueScheduler(
        queue: displayDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.display_agent"
    )
    
    // Current display info
    private var templateList = [DisplayTemplate]()
    private var updateTemplateList = [DisplayTemplate]()
    
    private var disposeBag = DisposeBag()
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Close", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleClose),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ControlFocus", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleControlFocus),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ControlScroll", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleControlScroll),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Update", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleUpdate),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "FullText1", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "FullText2", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "FullText3", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageText1", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageText2", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageText3", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageText4", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "TextList1", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "TextList2", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "TextList3", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "TextList4", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageList1", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageList2", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageList3", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Weather1", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Weather2", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Weather3", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Weather4", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Weather5", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "FullImage", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Score1", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Score2", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SearchList1", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SearchList2", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CommerceList", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CommerceOption", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CommercePrice", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CommerceInfo", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Call1", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Call2", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Call3", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Timer", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Dummy", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CustomTemplate", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay)
    ]
  
    public init(
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable,
        sessionManager: SessionManageable,
        focusManager: FocusManageable
    ) {
        self.upstreamDataSender = upstreamDataSender
        self.playSyncManager = playSyncManager
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        self.sessionManager = sessionManager
        self.focusManager = focusManager
        
        playSyncManager.add(delegate: self)
        contextManager.add(delegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        focusManager.add(channelDelegate: self)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - DisplayAgentProtocol

public extension DisplayAgent {
    @discardableResult func elementDidSelect(templateId: String, token: String, postback: [String: AnyHashable]?, completion: ((StreamDataState) -> Void)?) -> String {
        let eventIdentifier = EventIdentifier()
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let item = self.templateList.first(where: { $0.templateId == templateId }) else {
                // TODO error 정의
                completion?(.finished)
                return
            }

            self.contextManager.getContexts { [weak self] contextPayload in
                guard let self = self else { return }
                
                self.upstreamDataSender.sendEvent(
                    Event(
                        playServiceId: item.template.playServiceId,
                        typeInfo: .elementSelected(token: token, postback: postback)
                    ).makeEventMessage(
                        property: self.capabilityAgentProperty,
                        eventIdentifier: eventIdentifier,
                        referrerDialogRequestId: item.dialogRequestId,
                        contextPayload: contextPayload
                    ),
                    completion: completion
                )
            }
        }
        return eventIdentifier.dialogRequestId
    }
    
    func notifyUserInteraction() {
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.templateList
                .filter { $0.template.contextLayer != .overlay }
                .forEach { self.playSyncManager.resetTimer(property: $0.template.playSyncProperty) }
        }
    }
}

// MARK: - ContextInfoDelegate

extension DisplayAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: @escaping (ContextInfo?) -> Void) {
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            let item = self.templateList.first
            var payload: [String: AnyHashable?] = [
                "version": self.capabilityAgentProperty.version,
                "token": item?.template.token,
                "playServiceId": item?.template.playServiceId
            ]
            if let item = item, let delegate = self.delegate {
                let semaphore = DispatchSemaphore(value: 0)
                delegate.displayAgentRequestContext(templateId: item.templateId) { (displayContext) in
                    payload["focusedItemToken"] = displayContext?.focusedItemToken
                    payload["visibleTokenList"] = displayContext?.visibleTokenList
                    
                    semaphore.signal()
                }
                if semaphore.wait(timeout: .now() + .seconds(5)) == .timedOut {
                    log.error("`displayAgentRequestContext` completion block does not called")
                }
            }
            completion(ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
        }
    }
}

// MARK: - PlaySyncDelegate

extension DisplayAgent: PlaySyncDelegate {
    public func playSyncDidRelease(property: PlaySyncProperty, messageId: String) {
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.templateList
                .filter { $0.template.playSyncProperty == property && $0.templateId == messageId }
                .forEach {
                    if self.removeRenderedTemplate(item: $0) {
                        self.delegate?.displayAgentDidClear(templateId: $0.templateId)
                    }
            }
        }
    }
}

// MARK: - FocusChannelDelegate

extension DisplayAgent: FocusChannelDelegate {
    public func focusChannelPriority() -> FocusChannelPriority {
        return .background
    }
    
    public func focusChannelDidChange(focusState: FocusState) {
        log.info(focusState)
    }
}

// MARK: - Private(Directive, Event)

private extension DisplayAgent {
    func handleClose() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payload = try? JSONDecoder().decode(DisplayClosePayload.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }

            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard let item = self.templateList.first(where: { $0.template.playServiceId == payload.playServiceId }) else {
                    self.sendEvent(
                        typeInfo: .closeFailed,
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
                    return
                }
                
                self.playSyncManager.stopPlay(dialogRequestId: item.dialogRequestId)
                self.sendEvent(
                    typeInfo: .closeSucceeded,
                    playServiceId: payload.playServiceId,
                    referrerDialogRequestId: directive.header.dialogRequestId
                )
            }
        }
    }
    
    func handleControlFocus() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payload = try? JSONDecoder().decode(DisplayControlPayload.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            
            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard let item = self.templateList.first(where: { $0.template.playServiceId == payload.playServiceId }) else {
                    self.sendEvent(
                        typeInfo: .controlFocusFailed(direction: payload.direction),
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
                    return
                }
                
                self.delegate?.displayAgentShouldMoveFocus(templateId: item.templateId, direction: payload.direction) { [weak self] focusResult in
                    guard let self = self else { return }
                    
                    self.playSyncManager.resetTimer(property: item.template.playSyncProperty)
                    let typeInfo: Event.TypeInfo = focusResult ? .controlFocusSucceeded(direction: payload.direction) : .controlFocusFailed(direction: payload.direction)
                    self.sendEvent(
                        typeInfo: typeInfo,
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
                }
            }
        }
    }
    
    func handleControlScroll() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payload = try? JSONDecoder().decode(DisplayControlPayload.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }

            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard let item = self.templateList.first(where: { $0.template.playServiceId == payload.playServiceId }) else {
                    self.sendEvent(
                        typeInfo: .controlScrollFailed(direction: payload.direction),
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
                    return
                }
                self.delegate?.displayAgentShouldScroll(templateId: item.templateId, direction: payload.direction) { [weak self] scrollResult in
                    guard let self = self else { return }
                    
                    self.playSyncManager.resetTimer(property: item.template.playSyncProperty)
                    let typeInfo: Event.TypeInfo = scrollResult ? .controlScrollSucceeded(direction: payload.direction) : .controlScrollFailed(direction: payload.direction)
                    self.sendEvent(
                        typeInfo: typeInfo,
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
                }
            }
        }
    }
    
    func handleUpdate() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let template = try? JSONDecoder().decode(DisplayTemplate.Payload.self, from: directive.payload)  else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }

            let updateDisplayTemplate = DisplayTemplate(
                type: directive.header.type,
                payload: directive.payload,
                templateId: directive.header.messageId,
                dialogRequestId: directive.header.dialogRequestId,
                template: template
            )
            
            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self, let delegate = self.delegate else { return }
                guard let item = self.templateList.first(where: { $0.template.token == updateDisplayTemplate.template.token }) else { return }

                self.updateTemplateList.append(updateDisplayTemplate)
                self.playSyncManager.resetTimer(property: item.template.playSyncProperty)
                self.sessionManager.activate(dialogRequestId: updateDisplayTemplate.dialogRequestId, category: .display)
                delegate.displayAgentShouldUpdate(templateId: item.templateId, template: updateDisplayTemplate)
            }
        }
    }
    
    func handleDisplay() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            guard let template = try? JSONDecoder().decode(DisplayTemplate.Payload.self, from: directive.payload)  else {
                completion(.failed("Invalid payload"))
                return
            }
            
            let item = DisplayTemplate(
                type: directive.header.type,
                payload: directive.payload,
                templateId: directive.header.messageId,
                dialogRequestId: directive.header.dialogRequestId,
                template: template
            )
            
            self.displayDispatchQueue.async { [weak self] in
                guard let self = self else {
                    completion(.canceled)
                    return
                }
                defer {
                    self.focusManager.releaseFocus(channelDelegate: self)
                    completion(.finished)
                }
                
                self.focusManager.requestFocus(channelDelegate: self)
                self.sessionManager.activate(dialogRequestId: item.dialogRequestId, category: .display)
                self.playSyncManager.startPlay(
                    property: item.template.playSyncProperty,
                    info: PlaySyncInfo(
                        playStackServiceId: item.template.playStackControl?.playServiceId,
                        dialogRequestId: item.dialogRequestId,
                        messageId: item.templateId,
                        duration: item.template.duration?.time ?? self.defaultDisplayTempalteDuration.time
                    )
                )
                
                let semaphore = DispatchSemaphore(value: 0)
                delegate.displayAgentShouldRender(template: item) { [weak self] in
                    defer { semaphore.signal() }
                    guard let self = self else { return }
                    guard let displayObject = $0 else {
                        self.sessionManager.deactivate(dialogRequestId: item.dialogRequestId, category: .display)
                        self.playSyncManager.endPlay(property: item.template.playSyncProperty)
                        return
                    }
                    
                    // Release sync when removed all of template(May be closed by user).
                    Reactive(displayObject).deallocated
                        .observeOn(self.displayScheduler)
                        .subscribe({ [weak self] _ in
                            guard let self = self else { return }
                            
                            if self.removeRenderedTemplate(item: item) {
                                self.playSyncManager.stopPlay(dialogRequestId: item.dialogRequestId)
                            }
                        }).disposed(by: self.disposeBag)
                    
                    self.setRenderedTemplate(item: item)
                }
                if semaphore.wait(timeout: .now() + .seconds(5)) == .timedOut {
                    log.error("`displayAgentShouldRender` completion block does not called")
                }
            }
        }
    }
}

// MARK: - Private (Event)

private extension DisplayAgent {
    @discardableResult func sendEvent(
        typeInfo: Event.TypeInfo,
        playServiceId: String,
        referrerDialogRequestId: String? = nil,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        let eventIdentifier = EventIdentifier()
        contextManager.getContexts(namespace: capabilityAgentProperty.name) { [weak self] contextPayload in
            guard let self = self else { return }
            
            self.upstreamDataSender.sendEvent(
                Event(
                    playServiceId: playServiceId,
                    typeInfo: typeInfo
                ).makeEventMessage(
                    property: self.capabilityAgentProperty,
                    eventIdentifier: eventIdentifier,
                    referrerDialogRequestId: referrerDialogRequestId,
                    contextPayload: contextPayload
                ),
                completion: completion
            )
        }
        return eventIdentifier.dialogRequestId
    }
}

// MARK: - Private

private extension DisplayAgent {
    func setRenderedTemplate(item: DisplayTemplate) {
        templateList
            .filter { $0.template.contextLayer == item.template.contextLayer }
            .forEach { removeRenderedTemplate(item: $0) }
        templateList.insert(item, at: 0)
    }
    
    @discardableResult func removeRenderedTemplate(item: DisplayTemplate) -> Bool {
        guard templateList.contains(where: { $0.templateId == item.templateId }) else { return false }
        
        templateList.removeAll { $0.templateId == item.templateId }
        deactivateSession(dialogRequestId: item.dialogRequestId)
        updateTemplateList
            .filter { $0.template.token == item.template.token }
            .forEach { deactivateSession(dialogRequestId: $0.dialogRequestId) }
        updateTemplateList.removeAll { $0.template.token == item.template.token }
        return true
    }
    
    func deactivateSession(dialogRequestId: String) {
        guard templateList.contains(where: { $0.dialogRequestId == dialogRequestId }) == false else { return }
        sessionManager.deactivate(dialogRequestId: dialogRequestId, category: .display)
    }
}
