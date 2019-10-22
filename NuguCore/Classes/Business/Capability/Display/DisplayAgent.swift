//
//  DisplayAgent.swift
//  NuguCore
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

import NuguInterface

final public class DisplayAgent: DisplayAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .display, version: "1.0")
    
    private let displayDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.display_agent", qos: .userInitiated)
    
    public var messageSender: MessageSendable!
    public var playSyncManager: PlaySyncManageable!
    
    private var renderingInfos = [DisplayRenderingInfo]()
    
    // Current display info
    private var currentItem: DisplayTemplate?
    
    public init() {
        log.info("")
    }
    
    deinit {
        log.info("")
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
            guard let info = self.renderingInfos.first(where: { $0.currentItem?.messageId == templateId }),
                let template = info.currentItem else { return }
            
            self.sendEvent(
                Event(
                    typeInfo: .elementSelected(
                        playServiceId: template.playServiceId,
                        token: token
                    )),
                context: self.provideContext(),
                dialogRequestId: TimeUUID().hexString,
                by: self.messageSender
            )
        }
    }
    
    func clearDisplay(delegate: DisplayAgentDelegate) {
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let info = self.renderingInfos.first(where: { $0.delegate === delegate }),
                let template = info.currentItem else { return }
            
            self.removeRenderedTemplate(delegate: delegate)
            if self.hasRenderedDisplay(template: template) == false {
                self.playSyncManager.releaseSyncImmediately(dialogRequestId: template.dialogRequestId, playServiceId: template.playServiceId)
            }
        }
    }
}

// MARK: - HandleDirectiveDelegate

extension DisplayAgent: HandleDirectiveDelegate {
    public func handleDirectiveTypeInfos() -> DirectiveTypeInfos {
        return DirectiveTypeInfo.allDictionaryCases
    }
    
    public func handleDirective(
        _ directive: DirectiveProtocol,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        
        completionHandler(display(directive: directive))
    }
}

// MARK: - ProvideContextDelegate

extension DisplayAgent: ProvideContextDelegate {
    public func provideContext() -> ContextInfo {
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
    
    public func playSyncDuration() -> DisplayTemplate.Common.Duration {
        return currentItem?.duration ?? .short
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
                        if delegate.displayAgentShouldRender(template: item) {
                            rendered = true
                            self.setRenderedTemplate(delegate: delegate, template: item)
                        }
                }
                if rendered == false {
                    self.currentItem = nil
                    self.playSyncManager.cancelSync(delegate: self, dialogRequestId: dialogRequestId, playServiceId: item.playServiceId)
                }
            case .releasing:
                var cleared = true
                self.renderingInfos
                    .filter { $0.currentItem?.messageId == item.messageId }
                    .compactMap { $0.delegate }
                    .forEach { delegate in
                        if delegate.displayAgentShouldClear(template: item) == false {
                            cleared = false
                        }
                }
                if cleared {
                    self.playSyncManager.releaseSync(delegate: self, dialogRequestId: dialogRequestId, playServiceId: item.playServiceId)
                }
            case .released:
                if let item = self.currentItem {
                    self.currentItem = nil
                    self.renderingInfos
                        .filter { $0.currentItem?.messageId == item.messageId }
                        .compactMap { $0.delegate }
                        .forEach { self.removeRenderedTemplate(delegate: $0) }
                }
            case .prepared:
                break
            }
        }
    }
}

// MARK: - Private(Directive, Event)

private extension DisplayAgent {
    func display(directive: DirectiveProtocol) -> Result<Void, Error> {
        log.info("\(directive.header.type)")

        return Result { [weak self] in
            guard let self = self else { return }
            
            guard let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Unknown template")
            }
            
            guard let data = directive.payload.data(using: .utf8) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
            }
            
            switch directiveTypeInfo {
            case .fullText1, .fullText2, .imageText1, .imageText2, .imageText3, .imageText4:
                let displayItem = try JSONDecoder().decode(DisplayTemplate.BodyTemplate.self, from: data)
                self.currentItem = DisplayTemplate(
                    type: directiveTypeInfo.type,
                    typeInfo: .bodyTemplate(item: displayItem),
                    messageId: directive.header.messageID,
                    dialogRequestId: directive.header.dialogRequestID
                )
            case .textList1, .textList2, .textList3, .imageList1, .imageList2:
                let displayItem = try JSONDecoder().decode(DisplayTemplate.ListTemplate.self, from: data)
                self.currentItem = DisplayTemplate(
                    type: directiveTypeInfo.type,
                    typeInfo: .listTemplate(item: displayItem),
                    messageId: directive.header.messageID,
                    dialogRequestId: directive.header.dialogRequestID
                )
            case .customTemplate:
                throw HandleDirectiveError.handleDirectiveError(message: "Unsupported template")
            }
            if let item = self.currentItem {
                self.playSyncManager.startSync(delegate: self, dialogRequestId: item.dialogRequestId, playServiceId: item.playServiceId)
            }
        }
    }
}

// MARK: - Private

private extension DisplayAgent {
    func setRenderedTemplate(delegate: DisplayAgentDelegate, template: DisplayTemplate) {
        remove(delegate: delegate)
        let info = DisplayRenderingInfo(delegate: delegate, currentItem: template)
        renderingInfos.append(info)
        delegate.displayAgentDidRender(template: template)
    }
    
    func removeRenderedTemplate(delegate: DisplayAgentDelegate) {
        guard let template = self.renderingInfos.first(where: { $0.delegate === delegate })?.currentItem else { return }
        
        remove(delegate: delegate)
        let info = DisplayRenderingInfo(delegate: delegate, currentItem: nil)
        renderingInfos.append(info)
        delegate.displayAgentDidClear(template: template)
    }
    
    func hasRenderedDisplay(template: DisplayTemplate) -> Bool {
        return renderingInfos.contains { $0.currentItem?.messageId == template.messageId }
    }
}
