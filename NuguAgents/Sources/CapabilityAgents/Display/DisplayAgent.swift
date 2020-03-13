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
    
    // Private
    private let playSyncManager: PlaySyncManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    
    private let displayDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.display_agent", qos: .userInitiated)
    private lazy var displayScheduler = SerialDispatchQueueScheduler(
        queue: displayDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.display_agent"
    )
    
    private var renderingInfos = [DisplayRenderingInfo]()
    private var timerInfos = [String: Bool]()
    
    // Current display info
    private var currentItem: DisplayTemplate?
    
    private var disposeBag = DisposeBag()
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Close", medium: .none, isBlocking: false, directiveHandler: handleClose),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Focus", medium: .none, isBlocking: false, directiveHandler: handleFocus),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Scroll", medium: .none, isBlocking: false, directiveHandler: handleScroll),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Update", medium: .none, isBlocking: false, directiveHandler: handleUpdate),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "FullText1", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "FullText2", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "FullText3", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageText1", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageText2", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageText3", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageText4", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "TextList1", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "TextList2", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "TextList3", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "TextList4", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageList1", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageList2", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ImageList3", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Weather1", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Weather2", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Weather3", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Weather4", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Weather5", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "FullImage", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Score1", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Score2", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SearchList1", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "SearchList2", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CommerceList", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CommerceOption", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CommercePrice", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CommerceInfo", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Call1", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Call2", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Call3", medium: .audio, isBlocking: true, directiveHandler: handleDisplay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "CustomTemplate", medium: .audio, isBlocking: true, directiveHandler: handleDisplay)
    ]
  
    public init(
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        self.upstreamDataSender = upstreamDataSender
        self.playSyncManager = playSyncManager
        self.directiveSequencer = directiveSequencer
        
        contextManager.add(provideContextDelegate: self)
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
    
    func elementDidSelect(templateId: String, token: String) {
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let info = self.renderingInfos.first(where: { $0.currentItem?.templateId == templateId }),
                let template = info.currentItem else { return }
            
            self.upstreamDataSender.sendEvent(
                upstreamEventMessage: Event(
                    playServiceId: template.playServiceId,
                    typeInfo: .elementSelected(token: token)
                ).makeEventMessage(agent: self)
            )
        }
    }
    
    func stopRenderingTimer(templateId: String) {
        timerInfos[templateId] = false
    }
}

// MARK: - ContextInfoDelegate

extension DisplayAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completionHandler: @escaping (ContextInfo?) -> Void) {
        let sendContext = { [weak self] in
            guard let self = self else {
                completionHandler(nil)
                return
            }
            var payload: [String: Any?] = [
                "version": self.capabilityAgentProperty.version,
                "token": self.currentItem?.token,
                "playServiceId": self.currentItem?.playServiceId
            ]
            if let info = self.renderingInfos.first(where: { $0.currentItem?.templateId == self.currentItem?.templateId }),
                let delegate = info.delegate {
                payload["focusedItemToken"] = (info.currentItem?.focusable ?? false) ? delegate.displayAgentFocusedItemToken() : nil
                payload["visibleTokenList"] = delegate.displayAgentVisibleTokenList()
            }
            completionHandler(ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
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
    public func playSyncIsDisplay() -> Bool {
        return true
    }
    
    public func playSyncDuration() -> PlaySyncDuration {
        var playSyncDuration: PlaySyncDuration {
            switch currentItem?.duration {
            case .short:
                return .short
            case .mid:
                return .mid
            case .long:
                return .long
            case .longest:
                return .longest
            default:
                return .short
            }
        }

        return playSyncDuration
    }
    
    public func playSyncDidChange(state: PlaySyncState, dialogRequestId: String) {
        log.info("\(state)")
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let item = self.currentItem, item.dialogRequestId == dialogRequestId else { return }
            
            switch state {
            case .synced:
                break
            case .releasing:
                if self.timerInfos[item.templateId] != false {
                    self.renderingInfos
                        .filter { $0.currentItem?.templateId == item.templateId }
                        .compactMap { $0.delegate }
                        .forEach { delegate in
                            DispatchQueue.main.sync {
                                delegate.displayAgentShouldClear(template: item, reason: .timer)
                            }
                    }
                }
            case .released:
                self.currentItem = nil
                self.renderingInfos
                    .filter({ (rederingInfo) -> Bool in
                        guard let template = rederingInfo.currentItem, let delegate = rederingInfo.delegate else { return false}
                        return self.removeRenderedTemplate(delegate: delegate, template: template)
                    })
                    .compactMap { $0.delegate }
                    .forEach { delegate in
                        DispatchQueue.main.sync {
                            delegate.displayAgentShouldClear(template: item, reason: .directive)
                        }
                }
            case .prepared:
                break
            }
        }
    }
}

// MARK: - Private(Directive, Event)

private extension DisplayAgent {
    func handleClose() -> HandleDirective {
        return { [weak self] directive, completionHandler in
            completionHandler(
                Result { [weak self] in
                    guard let self = self else { return }
                    guard let data = directive.payload.data(using: .utf8) else {
                        throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
                    }
                    
                    let payload = try JSONDecoder().decode(DisplayClosePayload.self, from: data)
                    
                    self.upstreamDataSender.sendEvent(
                        upstreamEventMessage: Event(
                            playServiceId: payload.playServiceId,
                            typeInfo: self.currentItem?.playServiceId == payload.playServiceId ? .closeSucceeded : .closeFailed
                        ).makeEventMessage(agent: self)
                    )
                    
                    if let item = self.currentItem, item.playServiceId == payload.playServiceId {
                        self.playSyncManager.releaseSyncImmediately(dialogRequestId: item.dialogRequestId, playServiceId: item.playStackServiceId)
                    }
                }
            )
        }
    }
    
    func handleFocus() -> HandleDirective {
        return { [weak self] directive, completionHandler in
            completionHandler(
                Result { [weak self] in
                    guard let self = self else { return }
                    guard let data = directive.payload.data(using: .utf8) else {
                        throw HandleDirectiveError.handleDirectiveError(message: "Unknown template")
                    }
                    
                    let payload = try JSONDecoder().decode(DisplayControlPayload.self, from: data)
                    
                    guard let item = self.currentItem,
                        item.playServiceId == payload.playServiceId,
                        let info = self.renderingInfos.first(where: { $0.currentItem?.templateId == item.templateId }),
                        let delegate = info.delegate else {
                            self.upstreamDataSender.sendEvent(
                                upstreamEventMessage: Event(
                                    playServiceId: payload.playServiceId,
                                    typeInfo: .controlFocusFailed
                                ).makeEventMessage(agent: self)
                            )
                            return
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        let focusResult = delegate.displayAgentShouldMoveFocus(direction: payload.direction)
                        self.upstreamDataSender.sendEvent(
                            upstreamEventMessage: Event(
                                playServiceId: payload.playServiceId,
                                typeInfo: focusResult ? .controlFocusSucceeded : .controlFocusFailed
                            ).makeEventMessage(agent: self)
                        )
                    }
            })
        }
    }
        
    func handleScroll() -> HandleDirective {
        return { [weak self] directive, completionHandler in
            completionHandler(
                Result { [weak self] in
                    guard let self = self else { return }
                    guard let data = directive.payload.data(using: .utf8) else {
                        throw HandleDirectiveError.handleDirectiveError(message: "Unknown template")
                    }
                    
                    let payload = try JSONDecoder().decode(DisplayControlPayload.self, from: data)
                    
                    guard let item = self.currentItem,
                        item.playServiceId == payload.playServiceId,
                        let info = self.renderingInfos.first(where: { $0.currentItem?.templateId == item.templateId }),
                        let delegate = info.delegate else {
                            self.upstreamDataSender.sendEvent(
                                upstreamEventMessage: Event(
                                    playServiceId: payload.playServiceId,
                                    typeInfo: .controlScrollFailed
                                ).makeEventMessage(agent: self)
                            )
                            return
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        let scrollResult = delegate.displayAgentShouldScroll(direction: payload.direction)
                        self.upstreamDataSender.sendEvent(
                            upstreamEventMessage: Event(
                                playServiceId: payload.playServiceId,
                                typeInfo: scrollResult ? .controlScrollSucceeded : .controlScrollFailed
                            ).makeEventMessage(agent: self)
                        )
                    }
            })
        }
    }
    
    func handleUpdate() -> HandleDirective {
        return { [weak self] directive, completionHandler in
            log.info("\(directive.header.type)")
            completionHandler(
                Result { [weak self] in
                    guard let self = self else { return }
                    
                    guard let payloadAsData = directive.payload.data(using: .utf8),
                        let payloadDictionary = try? JSONSerialization.jsonObject(with: payloadAsData, options: []) as? [String: Any],
                        let token = payloadDictionary["token"] as? String,
                        let playServiceId = payloadDictionary["playServiceId"] as? String else {
                            throw HandleDirectiveError.handleDirectiveError(message: "Invalid token or playServiceId in payload")
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
                    
                    guard let info = self.renderingInfos.first(where: { $0.currentItem?.templateId == updateDisplayTemplate.templateId }),
                        let delegate = info.delegate else { return }
                    DispatchQueue.main.async {
                        delegate.displayAgentShouldUpdate(template: updateDisplayTemplate)
                    }
                }
            )
        }
    }
    
    func handleDisplay() -> HandleDirective {
        return { [weak self] directive, completionHandler in
            guard let self = self else { return completionHandler(.success(())) }
            guard let payloadAsData = directive.payload.data(using: .utf8),
                let payloadDictionary = try? JSONSerialization.jsonObject(with: payloadAsData, options: []) as? [String: Any],
                let token = payloadDictionary["token"] as? String,
                let playServiceId = payloadDictionary["playServiceId"] as? String else {
                    completionHandler(.failure(HandleDirectiveError.handleDirectiveError(message: "Invalid token or playServiceId in payload")))
                    return
            }
            
            log.info("\(directive.header.type)")
            
            let duration = payloadDictionary["duration"] as? String ?? DisplayTemplate.Duration.short.rawValue
            let playStackServiceId = (payloadDictionary["playStackControl"] as? [String: Any])?["playServiceId"] as? String
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

            self.displayDispatchQueue.async { [weak self] in
                guard let self = self else { return completionHandler(.success(())) }
                self.currentItem = item
                
                var rendered = false
                self.renderingInfos
                    .compactMap { $0.delegate }
                    .forEach { delegate in
                        rendered = self.setRenderedTemplate(delegate: delegate, template: item) || rendered
                }
                if rendered == true {
                    self.currentItem = item
                    self.playSyncManager.startSync(
                        delegate: self,
                        dialogRequestId: item.dialogRequestId,
                        playServiceId: item.playStackServiceId
                    )
                }
                
                completionHandler(.success(()))
            }
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
                    self.playSyncManager.releaseSyncImmediately(dialogRequestId: template.dialogRequestId, playServiceId: template.playStackServiceId)
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
        self.timerInfos.removeValue(forKey: template.templateId)
        
        return true
    }
    
    func hasRenderedDisplay(template: DisplayTemplate) -> Bool {
        displayDispatchQueue.precondition(.onQueue)
        return renderingInfos.contains { $0.currentItem?.templateId == template.templateId }
    }
}
