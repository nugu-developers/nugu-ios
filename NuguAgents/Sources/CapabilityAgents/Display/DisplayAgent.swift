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
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .display, version: "1.9")
    
    public weak var delegate: DisplayAgentDelegate?
    public var defaultDisplayTempalteDuration: DisplayTemplateDuration = .short
    
    // Private
    private let playSyncManager: PlaySyncManageable
    private let contextManager: ContextManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    private let sessionManager: SessionManageable
    private let interactionControlManager: InteractionControlManageable
    private var currentInteractionControl: InteractionControl?
    
    private let displayDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.display_agent", qos: .userInitiated)
    private lazy var displayScheduler = SerialDispatchQueueScheduler(
        queue: displayDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.display_agent"
    )
    
    // Current display info
    private var prefetchDisplayTemplate: DisplayTemplate?
    private var templateList = [DisplayTemplate]()
    private var updateTemplateList = [DisplayTemplate]()
    private let displayCloseResult = PublishSubject<String>()
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var playSyncObserver: Any?
    
    private var disposeBag = DisposeBag()
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Close", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleClose),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ControlFocus", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleControlFocus),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ControlScroll", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleControlScroll),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Update", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleUpdate),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "RedirectTriggerChild", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleRedirectTriggerChild)
    ] + [
        "FullText1", "FullText2", "FullText3",
        "ImageText1", "ImageText2", "ImageText3", "ImageText4", "ImageText5",
        "TextList1", "TextList2", "TextList3", "TextList4",
        "ImageList1", "ImageList2", "ImageList3",
        "Weather1", "Weather2", "Weather3", "Weather4", "Weather5",
        "FullImage",
        "Score1", "Score2",
        "SearchList1", "SearchList2", "UnifiedSearch1",
        "CommerceList", "CommerceOption", "CommercePrice", "CommerceInfo",
        "Call1", "Call2", "Call3",
        "Timer",
        "Dummy",
        "CustomTemplate",
        "TabExtension"
    ].map({ (name) in
        DirectiveHandleInfo(
            namespace: capabilityAgentProperty.name,
            name: name,
            blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true),
            preFetch: prefetchDisplay,
            directiveHandler: handleDisplay
        )
    })
  
    public init(
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable,
        sessionManager: SessionManageable,
        interactionControlManager: InteractionControlManageable
    ) {
        self.upstreamDataSender = upstreamDataSender
        self.playSyncManager = playSyncManager
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        self.sessionManager = sessionManager
        self.interactionControlManager = interactionControlManager
        
        contextManager.addProvider(contextInfoProvider)
        addPlaySyncObserver(playSyncManager)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
        removePlaySyncObserver()
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        self.displayDispatchQueue.async { [weak self] in
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

// MARK: - DisplayAgentProtocol

public extension DisplayAgent {
    @discardableResult func elementDidSelect(templateId: String, token: String, postback: [String: AnyHashable]?, completion: ((StreamDataState) -> Void)?) -> String {
        return sendFullContextEvent(elementSelected(
            templateId: templateId,
            token: token,
            postback: postback
        ), completion: completion).dialogRequestId
    }
    
    func notifyUserInteraction() {
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.templateList
                .filter { $0.template.contextLayer != .overlay }
                .forEach { self.playSyncManager.resetTimer(property: $0.template.playSyncProperty) }
        }
    }
    
    func triggerChild(templateId: String, data: [String: AnyHashable]) {
        self.displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.sendCompactContextEvent(self.triggerChild(templateId: templateId, data: data))
        }
    }
    
    func displayTemplateViewDidClear(templateId: String) {
        guard let item = templateList.first(where: { $0.templateId == templateId }) else { return }
        if self.removeRenderedTemplate(item: item) {
            self.playSyncManager.stopPlay(dialogRequestId: item.dialogRequestId)
            if templateList.count != 0 {
                guard let restartItem = templateList.first else { return }
                let displayHistoryControl = try? JSONDecoder().decode(DisplayHistoryControl.self, from: restartItem.payload)
                self.playSyncManager.startPlay(
                    property: restartItem.template.playSyncProperty,
                    info: PlaySyncInfo(
                        playStackServiceId: restartItem.template.playStackControl?.playServiceId,
                        dialogRequestId: restartItem.dialogRequestId,
                        messageId: restartItem.templateId,
                        duration: restartItem.template.duration?.time ?? self.defaultDisplayTempalteDuration.time,
                        displayHistoryControl: displayHistoryControl != nil ?
                        ["parent": displayHistoryControl?.historyControl.parent ?? false,
                         "child": displayHistoryControl?.historyControl.child ?? false,
                         "parentToken": displayHistoryControl?.historyControl.parentToken ?? ""] : nil
                    )
                )
            }
        }
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
            
            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self else {
                    completion(.finished)
                    return
                }
                
                guard let item = self.templateList.first(where: { $0.template.playServiceId == payload.playServiceId }) else {
                    self.sendCompactContextEvent(Event(
                        typeInfo: .closeFailed,
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    ).rx)
                    completion(.finished)
                    return
                }
                
                // Call `completion` after processing `close` directive
                self.displayCloseResult
                    .filter { $0 == item.dialogRequestId }
                    .take(1)
                    .subscribe(onCompleted: {
                        completion(.finished)
                    })
                    .disposed(by: self.disposeBag)

                self.playSyncManager.stopPlay(dialogRequestId: item.dialogRequestId)
                self.sendCompactContextEvent(Event(
                    typeInfo: .closeSucceeded,
                    playServiceId: payload.playServiceId,
                    referrerDialogRequestId: directive.header.dialogRequestId
                ).rx)
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
                    self.sendCompactContextEvent(Event(
                        typeInfo: .controlFocusFailed(direction: payload.direction),
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    ).rx)
                    return
                }
                
                self.delegate?.displayAgentShouldMoveFocus(templateId: item.templateId, direction: payload.direction, header: directive.header) { [weak self] focusResult in
                    guard let self = self else { return }
                    
                    self.playSyncManager.resetTimer(property: item.template.playSyncProperty)
                    let typeInfo: Event.TypeInfo = focusResult ? .controlFocusSucceeded(direction: payload.direction) : .controlFocusFailed(direction: payload.direction)
                    self.sendCompactContextEvent(Event(
                        typeInfo: typeInfo,
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    ).rx)
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
                guard let self = self, let delegate = self.delegate else { return }
                guard let item = self.templateList.first(where: { $0.template.playServiceId == payload.playServiceId }) else {
                    self.sendCompactContextEvent(Event(
                        typeInfo: .controlScrollFailed(direction: payload.direction, interactionControl: payload.interactionControl),
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    ).rx)
                    return
                }
                if let interactionControl = payload.interactionControl {
                    self.currentInteractionControl = interactionControl
                    self.interactionControlManager.start(mode: interactionControl.mode, category: self.capabilityAgentProperty.category)
                }
                delegate.displayAgentShouldScroll(templateId: item.templateId, direction: payload.direction, header: directive.header) { [weak self] scrollResult in
                    guard let self = self else { return }
                    self.playSyncManager.resetTimer(property: item.template.playSyncProperty)
                    
                    var typeInfo: Event.TypeInfo {
                        guard scrollResult else {
                            return .controlScrollFailed(direction: payload.direction, interactionControl: payload.interactionControl)
                        }
                        
                        return .controlScrollSucceeded(direction: payload.direction, interactionControl: payload.interactionControl)
                    }
                    
                    self.sendCompactContextEvent(Event(
                        typeInfo: typeInfo,
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    ).rx) { [weak self] state in
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
                header: directive.header,
                payload: directive.payload,
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
    
    func handleRedirectTriggerChild() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let triggerChildPayload = try? JSONDecoder().decode(DisplayRedirectTriggerChildPayload.self, from: directive.payload)  else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }

            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                self.sendCompactContextEvent(Event(
                    typeInfo: .triggerChild(parentToken: triggerChildPayload.parentToken, data: triggerChildPayload.data),
                    playServiceId: triggerChildPayload.playServiceId,
                    referrerDialogRequestId: directive.header.dialogRequestId
                ).rx)
            }
        }
    }
    
    func prefetchDisplay() -> PrefetchDirective {
        return { [weak self] directive in
            guard let template = try? JSONDecoder().decode(DisplayTemplate.Payload.self, from: directive.payload)  else {
                return
            }
            
            let item = DisplayTemplate(
                header: directive.header,
                payload: directive.payload,
                template: template
            )
            
            self?.displayDispatchQueue.async { [weak self] in
                self?.prefetchDisplayTemplate = item
                self?.setRenderedTemplate(item: item)
            }
        }
    }
    
    func handleDisplay() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            guard let item = self.prefetchDisplayTemplate, directive.header.messageId == item.header.messageId  else {
                completion(.failed("Message id does not match"))
                return
            }
            
            self.displayDispatchQueue.async { [weak self] in
                guard let self = self else {
                    completion(.canceled)
                    return
                }
                defer { completion(.finished) }
                
                let displayHistoryControl = try? JSONDecoder().decode(DisplayHistoryControl.self, from: directive.payload)
                
                self.sessionManager.activate(dialogRequestId: item.dialogRequestId, category: .display)
                self.playSyncManager.startPlay(
                    property: item.template.playSyncProperty,
                    info: PlaySyncInfo(
                        playStackServiceId: item.template.playStackControl?.playServiceId,
                        dialogRequestId: item.dialogRequestId,
                        messageId: item.templateId,
                        duration: item.template.duration?.time ?? self.defaultDisplayTempalteDuration.time,
                        displayHistoryControl: displayHistoryControl != nil ?
                        ["parent": displayHistoryControl?.historyControl.parent ?? false,
                         "child": displayHistoryControl?.historyControl.child ?? false,
                         "parentToken": displayHistoryControl?.historyControl.parentToken ?? ""] : nil
                    )
                )
                
                let semaphore = DispatchSemaphore(value: 0)
                delegate.displayAgentShouldRender(template: item, historyControl: displayHistoryControl?.historyControl) { [weak self] in
                    defer { semaphore.signal() }
                    guard let self = self else { return }
                    guard let displayObject = $0 else {
                        self.sessionManager.deactivate(dialogRequestId: item.dialogRequestId, category: .display)
                        self.playSyncManager.endPlay(property: item.template.playSyncProperty)
                        self.removeRenderedTemplate(item: item)
                        return
                    }
                    
                    // Release sync when removed all of template(May be closed by user).
                    Reactive(displayObject).deallocated
                        .observe(on: self.displayScheduler)
                        .subscribe({ [weak self] _ in
                            guard let self = self else { return }
                            if self.removeRenderedTemplate(item: item) {
                                self.playSyncManager.stopPlay(dialogRequestId: item.dialogRequestId)
                            }
                        }).disposed(by: self.disposeBag)
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

// MARK: - Private (Eventable)

private extension DisplayAgent {
    func elementSelected(templateId: String, token: String, postback: [String: AnyHashable]?) -> Single<Eventable> {
        return Single.create { [weak self] (observer) -> Disposable in
            guard let item = self?.templateList.first(where: { $0.templateId == templateId }) else {
                observer(.failure(NuguAgentError.invalidState))
                return Disposables.create()
            }
            
            let settingEvent = Event(
                    typeInfo: .elementSelected(token: token, postback: postback),
                    playServiceId: item.template.playServiceId,
                    referrerDialogRequestId: item.dialogRequestId
                )
            observer(.success(settingEvent))
            return Disposables.create()
        }.subscribe(on: displayScheduler)
    }
    
    func triggerChild(templateId: String, data: [String: AnyHashable]) -> Single<Eventable> {
        return Single.create { [weak self] (observer) -> Disposable in
            guard let item = self?.templateList.first(where: { $0.templateId == templateId }),
                  let targetServiceId = data["playServiceId"] as? String,
                  let innerData = data["data"] as? [String: AnyHashable] else {
                      observer(.failure(NuguAgentError.invalidState))
                      return Disposables.create()
                  }
            let triggerChildEvent = Event(
                typeInfo: .triggerChild(parentToken: item.template.token, data: innerData),
                playServiceId: targetServiceId,
                referrerDialogRequestId: item.dialogRequestId
            )
            observer(.success(triggerChildEvent))
            return Disposables.create()
        }.subscribe(on: displayScheduler)
    }
}

// MARK: - Private

private extension DisplayAgent {
    func setRenderedTemplate(item: DisplayTemplate) {
        let displayHistoryControl = try? JSONDecoder().decode(DisplayHistoryControl.self, from: item.payload)
        if displayHistoryControl?.historyControl.child != true {
            templateList
            // FIXME: Currently the application is not separating the display view according to 'LayerType'.
            // .filter { $0.template.contextLayer == item.template.contextLayer }
                .forEach { removeRenderedTemplate(item: $0) }
        }
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

// MARK: - Observers

private extension DisplayAgent {
    func addPlaySyncObserver(_ object: PlaySyncManageable) {
        playSyncObserver = object.observe(NuguCoreNotification.PlaySync.ReleasedProperty.self, queue: nil) { [weak self] (notification) in
            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                let releaseTemplateList = self.templateList
                    .filter { $0.template.playSyncProperty == notification.property && $0.templateId == notification.messageId }
                
                releaseTemplateList
                    .forEach {
                        if self.removeRenderedTemplate(item: $0) {
                            self.delegate?.displayAgentDidClear(templateId: $0.templateId)
                        }
                    }
                
                releaseTemplateList
                    .map { $0.dialogRequestId }
                    .forEach { self.displayCloseResult.onNext($0) }
            }
        }
    }
    
    func removePlaySyncObserver() {
        if let playSyncObserver = playSyncObserver {
            notificationCenter.removeObserver(playSyncObserver)
        }
    }
}
