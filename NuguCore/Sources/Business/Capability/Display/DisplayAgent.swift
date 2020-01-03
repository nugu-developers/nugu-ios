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

import RxSwift

final public class DisplayAgent: DisplayAgentProtocol, CapabilityDirectiveAgentable, CapabilityEventAgentable {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .display, version: "1.1")
    
    // CapabilityEventAgentable
    public let upstreamDataSender: UpstreamDataSendable
    
    // Private
    private let playSyncManager: PlaySyncManageable
    
    private let displayDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.display_agent", qos: .userInitiated)
    
    private var renderingInfos = [DisplayRenderingInfo]()
    private var timerInfos = [String: Bool]()
    
    // Current display info
    private var currentItem: DisplayTemplate?
    
    private var disposeBag = DisposeBag()
  
    public init(
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        log.info("")
        
        self.upstreamDataSender = upstreamDataSender
        self.playSyncManager = playSyncManager
        
        contextManager.add(provideContextDelegate: self)
        directiveSequencer.add(handleDirectiveDelegate: self)
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
            guard let info = self.renderingInfos.first(where: { $0.currentItem?.templateId == templateId }),
                let template = info.currentItem else { return }
            
            self.sendEvent(
                Event(
                    typeInfo: .elementSelected(
                        playServiceId: template.playServiceId,
                        token: token
                    )),
                dialogRequestId: TimeUUID().hexString
            )
        }
    }
    
    func stopRenderingTimer(templateId: String) {
        timerInfos[templateId] = false
    }
}

// MARK: - HandleDirectiveDelegate

extension DisplayAgent: HandleDirectiveDelegate {
    public func handleDirective(
        _ directive: Downstream.Directive,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        
        completionHandler(display(directive: directive))
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
    
    public func playSyncDuration() -> DisplayTemplate.Duration {
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
                    .filter { $0.currentItem?.templateId == item.templateId }
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
    func display(directive: Downstream.Directive) -> Result<Void, Error> {
        log.info("\(directive.header.type)")

        return Result { [weak self] in
            guard let self = self else { return }
            
            guard let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Unknown template")
            }
            
            guard let payloadAsData = directive.payload.data(using: .utf8),
                let payloadDictionary = try? JSONSerialization.jsonObject(with: payloadAsData, options: []) as? [String: Any],
                let token = payloadDictionary["token"] as? String,
                let playServiceId = payloadDictionary["playServiceId"] as? String else {
                    throw HandleDirectiveError.handleDirectiveError(message: "Invalid token or playServiceId in payload")
            }
            
            let duration = payloadDictionary["duration"] as? String ?? DisplayTemplate.Duration.short.rawValue
            let playStackServiceId = (payloadDictionary["playStackControl"] as? [String: Any])?["playServiceId"] as? String
                        
            self.currentItem = DisplayTemplate(
                type: directiveTypeInfo.type,
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
    }
}

// MARK: - Private

private extension DisplayAgent {
    func replace(delegate: DisplayAgentDelegate, template: DisplayTemplate?) {
        remove(delegate: delegate)
        let info = DisplayRenderingInfo(delegate: delegate, currentItem: template)
        renderingInfos.append(info)
    }
    
    func setRenderedTemplate(delegate: DisplayAgentDelegate, template: DisplayTemplate) -> Bool {
        return DispatchQueue.main.sync {
            guard let displayObject = delegate.displayAgentDidRender(template: template) else { return false }
            
            replace(delegate: delegate, template: template)
            
            Reactive(displayObject).deallocated.subscribe({ [weak self] _ in
                self?.removeRenderedTemplate(delegate: delegate, template: template)
            }).disposed(by: disposeBag)
            return true
        }
    }
    
    func removeRenderedTemplate(delegate: DisplayAgentDelegate, template: DisplayTemplate) {
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.renderingInfos.contains(
                where: { $0.delegate === delegate && $0.currentItem?.templateId == template.templateId }
                ) else { return }

            self.replace(delegate: delegate, template: nil)
            self.timerInfos.removeValue(forKey: template.templateId)
            if self.hasRenderedDisplay(template: template) == false {
                self.playSyncManager.releaseSyncImmediately(dialogRequestId: template.dialogRequestId, playServiceId: template.playStackServiceId)
            }
        }
    }
    
    func hasRenderedDisplay(template: DisplayTemplate) -> Bool {
        return renderingInfos.contains { $0.currentItem?.templateId == template.templateId }
    }
}
