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

final public class DisplayAgent: DisplayAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .display, version: "1.1")
    
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
        DirectiveHandleInfo(namespace: "Display", name: "Close", medium: .visual, isBlocking: false, handler: handleClose),
        DirectiveHandleInfo(namespace: "Display", name: "FullText1", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "FullText2", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "ImageText1", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "ImageText2", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "ImageText3", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "ImageText4", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "TextList1", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "TextList2", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "TextList3", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "TextList4", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "ImageList1", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "ImageList2", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "ImageList3", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "Weather1", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "Weather2", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "Weather3", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "Weather4", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "Weather5", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "FullImage", medium: .visual, isBlocking: false, handler: handleDisplay),
        DirectiveHandleInfo(namespace: "Display", name: "CustomTemplate", medium: .visual, isBlocking: false, handler: handleDisplay)
    ]
  
    public init(
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        log.info("")
        
        self.upstreamDataSender = upstreamDataSender
        self.playSyncManager = playSyncManager
        self.directiveSequencer = directiveSequencer
        
        contextManager.add(provideContextDelegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        log.info("")
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
            
            self.sendEvent(playServiceId: template.playServiceId, type: .elementSelected(token: token))
        }
    }
    
    func stopRenderingTimer(templateId: String) {
        timerInfos[templateId] = false
    }
}

// MARK: - ContextInfoDelegate

extension DisplayAgent: ContextInfoDelegate {
    public func contextInfoRequestContext() -> ContextInfo? {
        let payload: [String: Any?] = [
            "version": capabilityAgentProperty.version,
            "token": currentItem?.token,
            "playServiceId": currentItem?.playServiceId
        ]
        
        return ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 })
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
                var rendered = false
                self.renderingInfos
                    .compactMap { $0.delegate }
                    .forEach { delegate in
                        rendered = self.setRenderedTemplate(delegate: delegate, template: item) || rendered
                }
                if rendered == false {
                    self.currentItem = nil
                    self.playSyncManager.cancelSync(delegate: self, dialogRequestId: dialogRequestId, playServiceId: item.playStackServiceId)
                }
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
                    guard let item = self.currentItem, item.playServiceId == payload.playServiceId else {
                        self.sendEvent(playServiceId: payload.playServiceId, type: .closeFailed)
                        return
                    }
                    
                    self.sendEvent(playServiceId: payload.playServiceId, type: .closeSucceeded)
                    self.playSyncManager.releaseSyncImmediately(dialogRequestId: item.dialogRequestId, playServiceId: item.playStackServiceId)
                }
            )
        }
    }
    
    func handleDisplay() -> HandleDirective {
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
                    
                    let duration = payloadDictionary["duration"] as? String ?? DisplayTemplate.Duration.short.rawValue
                    let playStackServiceId = (payloadDictionary["playStackControl"] as? [String: Any])?["playServiceId"] as? String
                    
                    self.currentItem = DisplayTemplate(
                        type: directive.header.type,
                        payload: directive.payload,
                        templateId: directive.header.messageId,
                        dialogRequestId: directive.header.dialogRequestId,
                        token: token,
                        playServiceId: playServiceId,
                        playStackServiceId: playStackServiceId,
                        duration: DisplayTemplate.Duration(rawValue: duration)
                    )
                    
                    if let item = self.currentItem {
                        self.playSyncManager.startSync(delegate: self, dialogRequestId: item.dialogRequestId, playServiceId: item.playStackServiceId)
                    }
                }
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

// MARK: - private(Event)
private extension DisplayAgent {
    func sendEvent(playServiceId: String, type: Event.TypeInfo) {
        let event = Event(playServiceId: playServiceId, typeInfo: type)
        let header = UpstreamHeader(
            namespace: capabilityAgentProperty.name,
            name: event.name,
            version: capabilityAgentProperty.version,
            dialogRequestId: TimeUUID().hexString,
            messageId: TimeUUID().hexString
        )
        
        let contextPayload = ContextPayload(
            supportedInterfaces: [self.contextInfoRequestContext()].compactMap({ $0 }),
            client: []
        )
        
        let message = UpstreamEventMessage(
            payload: event.payload,
            header: header,
            contextPayload: contextPayload
        )

        self.upstreamDataSender.send(upstreamEventMessage: message)
    }
}
