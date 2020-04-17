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
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .display, version: "1.2")
    private let playSyncProperty = PlaySyncProperty(layerType: .info, contextType: .display)
    
    // Private
    private let playSyncManager: PlaySyncManageable
    private let contextManager: ContextManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    
    private let displayDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.display_agent", qos: .userInitiated)
    private lazy var displayScheduler = SerialDispatchQueueScheduler(
        queue: displayDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.display_agent"
    )
    
    private var renderingInfos = [DisplayRenderingInfo]()
    
    // Current display info
    private var currentItem: DisplayTemplate?
    
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
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CustomTemplate", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), directiveHandler: handleDisplay)
    ]
  
    public init(
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        self.upstreamDataSender = upstreamDataSender
        self.playSyncManager = playSyncManager
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        
        playSyncManager.add(delegate: self)
        contextManager.add(delegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - DisplayAgentProtocol

public extension DisplayAgent {
    func add(delegate: DisplayAgentDelegate) {
        remove(delegate: delegate)
        
        let info = DisplayRenderingInfo(delegate: delegate, currentItem: nil)
        renderingInfos.append(info)
    }
    
    func remove(delegate: DisplayAgentDelegate) {
        renderingInfos.removeAll { (info) -> Bool in
            return info.delegate == nil || info.delegate === delegate
        }
    }
    
    @discardableResult func elementDidSelect(templateId: String, token: String, completion: ((StreamDataState) -> Void)?) -> String {
        let dialogRequestId = TimeUUID().hexString
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let info = self.renderingInfos.first(where: { $0.currentItem?.templateId == templateId }),
                let template = info.currentItem else {
                    // TODO error 정의
                    completion?(.finished)
                    return
            }

            self.contextManager.getContexts { [weak self] contextPayload in
                guard let self = self else { return }
                
                self.upstreamDataSender.sendEvent(
                    Event(
                        playServiceId: template.playServiceId,
                        typeInfo: .elementSelected(token: token)
                    ).makeEventMessage(
                        property: self.capabilityAgentProperty,
                        dialogRequestId: dialogRequestId,
                        referrerDialogRequestId: template.dialogRequestId,
                        contextPayload: contextPayload
                    ),
                    completion: completion
                )
            }
        }
        return dialogRequestId
    }
    
    func notifyUserInteraction() {
        self.playSyncManager.resetTimer(property: playSyncProperty)
    }
}

// MARK: - ContextInfoDelegate

extension DisplayAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: @escaping (ContextInfo?) -> Void) {
        let sendContext = { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            var payload: [String: AnyHashable?] = [
                "version": self.capabilityAgentProperty.version,
                "token": self.currentItem?.token,
                "playServiceId": self.currentItem?.playServiceId
            ]
            if let info = self.renderingInfos.first(where: { $0.currentItem?.templateId == self.currentItem?.templateId }),
                let delegate = info.delegate {
                payload["focusedItemToken"] = (info.currentItem?.focusable ?? false) ? delegate.displayAgentFocusedItemToken() : nil
                payload["visibleTokenList"] = delegate.displayAgentVisibleTokenList()
            }
            completion(ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
        }
        
        if Thread.current.isMainThread {
            sendContext()
        } else {
            DispatchQueue.main.sync { sendContext() }
        }
    }
}

// MARK: - PlaySyncDelegate

extension DisplayAgent: PlaySyncDelegate {
    public func playSyncDidRelease(property: PlaySyncProperty, dialogRequestId: String) {
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard property == self.playSyncProperty, let item = self.currentItem, item.dialogRequestId == dialogRequestId else { return }
            
            self.currentItem = nil
            self.renderingInfos
                .filter({ (rederingInfo) -> Bool in
                    guard let template = rederingInfo.currentItem, let delegate = rederingInfo.delegate else { return false}
                    return self.removeRenderedTemplate(delegate: delegate, template: template)
                })
                .compactMap { $0.delegate }
                .forEach { delegate in
                    DispatchQueue.main.sync {
                        delegate.displayAgentShouldClear(template: item)
                    }
            }
        }
    }
}

// MARK: - Private(Directive, Event)

private extension DisplayAgent {
    func handleClose() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
            
            guard let payload = try? JSONDecoder().decode(DisplayClosePayload.self, from: directive.payload) else {
                log.error("Invalid payload")
                return
            }

            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard let item = self.currentItem, item.playServiceId == payload.playServiceId else {
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
            defer { completion() }
        
            guard let payload = try? JSONDecoder().decode(DisplayControlPayload.self, from: directive.payload) else {
                log.error("Invalid payload")
                return
            }
            
            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard let item = self.currentItem,
                    item.playServiceId == payload.playServiceId,
                    let delegate = self.renderingInfos.first(where: { $0.currentItem?.templateId == item.templateId })?.delegate else {
                        self.sendEvent(
                            typeInfo: .controlFocusFailed,
                            playServiceId: payload.playServiceId,
                            referrerDialogRequestId: directive.header.dialogRequestId
                        )
                        return
                }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let focusResult = delegate.displayAgentShouldMoveFocus(direction: payload.direction)
                    
                    let typeInfo: Event.TypeInfo = focusResult ? .controlFocusSucceeded : .controlFocusFailed
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
                log.error("Invalid payload")
                return
            }
            
            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard let item = self.currentItem,
                    item.playServiceId == payload.playServiceId,
                    let delegate = self.renderingInfos.first(where: { $0.currentItem?.templateId == item.templateId })?.delegate else {
                        self.sendEvent(
                            typeInfo: .controlScrollFailed,
                            playServiceId: payload.playServiceId,
                            referrerDialogRequestId: directive.header.dialogRequestId
                        )
                        return
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let scrollResult = delegate.displayAgentShouldScroll(direction: payload.direction)
                    
                    let typeInfo: Event.TypeInfo = scrollResult ? .controlScrollSucceeded : .controlScrollFailed
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
            defer { completion() }
            
            guard let payloadDictionary = directive.payloadDictionary,
                let token = payloadDictionary["token"] as? String,
                let playServiceId = payloadDictionary["playServiceId"] as? String else {
                    log.error("Invalid token or playServiceId in payload")
                    return
            }
            
            let updateDisplayTemplate = DisplayTemplate(
                type: directive.header.type,
                payload: directive.payload,
                templateId: directive.header.messageId,
                dialogRequestId: directive.header.dialogRequestId,
                token: token,
                playServiceId: playServiceId,
                playStackServiceId: nil,
                duration: nil,
                focusable: nil
            )
            
            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard let delegate = self.renderingInfos.first(where: { $0.currentItem?.templateId == updateDisplayTemplate.templateId })?.delegate else { return }
                
                DispatchQueue.main.async {
                    delegate.displayAgentShouldUpdate(template: updateDisplayTemplate)
                }
            }
        }
    }
    
    func handleDisplay() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payloadDictionary = directive.payloadDictionary,
                let token = payloadDictionary["token"] as? String,
                let playServiceId = payloadDictionary["playServiceId"] as? String else {
                    log.error("Invalid token or playServiceId in payload")
                    completion()
                    return
            }
            
            let duration = payloadDictionary["duration"] as? String ?? DisplayTemplate.Duration.short.rawValue
            let playStackServiceId = (payloadDictionary["playStackControl"] as? [String: AnyHashable])?["playServiceId"] as? String
            let focusable = payloadDictionary["focusable"] as? Bool
            
            let item = DisplayTemplate(
                type: directive.header.type,
                payload: directive.payload,
                templateId: directive.header.messageId,
                dialogRequestId: directive.header.dialogRequestId,
                token: token,
                playServiceId: playServiceId,
                playStackServiceId: playStackServiceId,
                duration: DisplayTemplate.Duration(rawValue: duration),
                focusable: focusable
            )

            self?.displayDispatchQueue.async { [weak self] in
                defer { completion() }
                
                guard let self = self else { return }
                
                let rendered = self.renderingInfos
                    .compactMap { $0.delegate }
                    .map { self.setRenderedTemplate(delegate: $0, template: item) }
                    .contains { $0 }
                if rendered == true {
                    self.currentItem = item
                    
                    self.playSyncManager.startPlay(
                        property: self.playSyncProperty,
                        duration: item.duration.time,
                        playServiceId: item.playStackServiceId,
                        dialogRequestId: item.dialogRequestId
                    )
                }
            }
        }
    }
}

// MARK: - Private (Event)

private extension DisplayAgent {
    func sendEvent(
        typeInfo: Event.TypeInfo,
        playServiceId: String,
        dialogRequestId: String = TimeUUID().hexString,
        referrerDialogRequestId: String? = nil,
        completion: ((StreamDataState) -> Void)? = nil
    ) {
        contextManager.getContexts(namespace: capabilityAgentProperty.name) { [weak self] contextPayload in
            guard let self = self else { return }
            
            self.upstreamDataSender.sendEvent(
                Event(
                    playServiceId: playServiceId,
                    typeInfo: typeInfo
                ).makeEventMessage(
                    property: self.capabilityAgentProperty,
                    dialogRequestId: dialogRequestId,
                    referrerDialogRequestId: referrerDialogRequestId,
                    contextPayload: contextPayload
                ),
                completion: completion
            )
        }
    }
}

// MARK: - Private

private extension DisplayAgent {
    func replace(delegate: DisplayAgentDelegate, template: DisplayTemplate?) {
        displayDispatchQueue.precondition(.onQueue)
        remove(delegate: delegate)
        let info = DisplayRenderingInfo(delegate: delegate, currentItem: template)
        renderingInfos.append(info)
    }
    
    func setRenderedTemplate(delegate: DisplayAgentDelegate, template: DisplayTemplate) -> Bool {
        displayDispatchQueue.precondition(.onQueue)
        guard let displayObject = DispatchQueue.main.sync(execute: { () -> AnyObject? in
            return delegate.displayAgentDidRender(template: template)
        }) else { return false }

        replace(delegate: delegate, template: template)
        
        Reactive(displayObject).deallocated
            .observeOn(displayScheduler)
            .subscribe({ [weak self] _ in
                guard let self = self else { return }
                
                if self.removeRenderedTemplate(delegate: delegate, template: template),
                    self.hasRenderedDisplay(template: template) == false {
                    // Release sync when removed all of template(May be closed by user).
                    self.playSyncManager.stopPlay(dialogRequestId: template.dialogRequestId)
                }
            }).disposed(by: disposeBag)
        return true
    }
    
    func removeRenderedTemplate(delegate: DisplayAgentDelegate, template: DisplayTemplate) -> Bool {
        displayDispatchQueue.precondition(.onQueue)
        guard self.renderingInfos.contains(
            where: { $0.delegate === delegate && $0.currentItem?.templateId == template.templateId }
            ) else { return false }
        
        self.replace(delegate: delegate, template: nil)
        
        return true
    }
    
    func hasRenderedDisplay(template: DisplayTemplate) -> Bool {
        displayDispatchQueue.precondition(.onQueue)
        return renderingInfos.contains { $0.currentItem?.templateId == template.templateId }
    }
}
