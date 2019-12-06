//
//  AudioPlayerDisplayManager.swift
//  NuguCore
//
//  Created by MinChul Lee on 2019/07/17.
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

final class AudioPlayerDisplayManager: AudioPlayerDisplayManageable {
    private let displayDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.audio_player_display", qos: .userInitiated)
    
    var playSyncManager: PlaySyncManageable!
    
    private var renderingInfos = [AudioPlayerDisplayRenderingInfo]()
    private var timerInfos = [String: Bool]()
    
    // Current display info
    private var currentItem: AudioPlayerDisplayTemplate?
    
    private var disposeBag = DisposeBag()
}

// MARK: - AudioPlayerDisplayManageable

extension AudioPlayerDisplayManager {
    func display(metaData: [String: Any], messageId: String, dialogRequestId: String, playStackServiceId: String?) {
        guard let data = try? JSONSerialization.data(withJSONObject: metaData, options: []),
            let displayItem = try? JSONDecoder().decode(AudioPlayerDisplayTemplate.AudioPlayer.self, from: data) else {
                log.error("Invalid metaData")
            return
        }
        
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.currentItem = AudioPlayerDisplayTemplate(
                type: displayItem.template.type,
                payload: displayItem,
                templateId: messageId,
                dialogRequestId: dialogRequestId,
                playStackServiceId: playStackServiceId
            )
            if let item = self.currentItem {
                self.playSyncManager.startSync(delegate: self, dialogRequestId: item.dialogRequestId, playServiceId: item.playStackServiceId)
            }
        }
    }
    
    func add(delegate: AudioPlayerDisplayDelegate) {
        remove(delegate: delegate)
        
        let info = AudioPlayerDisplayRenderingInfo(delegate: delegate, currentItem: nil)
        renderingInfos.append(info)
    }
    
    func remove(delegate: AudioPlayerDisplayDelegate) {
        renderingInfos.removeAll { (info) -> Bool in
            return info.delegate == nil || info.delegate === delegate
        }
    }
    
    func stopRenderingTimer(templateId: String) {
        timerInfos[templateId] = false
    }
}

// MARK: - PlaySyncDelegate

extension AudioPlayerDisplayManager: PlaySyncDelegate {
    public func playSyncIsDisplay() -> Bool {
        return true
    }
    
    public func playSyncDuration() -> DisplayTemplate.Duration {
        return .short
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
                                delegate.audioPlayerDisplayShouldClear(template: item, reason: .timer)
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
                            delegate.audioPlayerDisplayShouldClear(template: item, reason: .directive)
                        }
                }
            case .prepared:
                break
            }
        }
    }
}

// MARK: - Private

private extension AudioPlayerDisplayManager {
    func replace(delegate: AudioPlayerDisplayDelegate, template: AudioPlayerDisplayTemplate?) {
        remove(delegate: delegate)
        let info = AudioPlayerDisplayRenderingInfo(delegate: delegate, currentItem: template)
        renderingInfos.append(info)
    }
    
    func setRenderedTemplate(delegate: AudioPlayerDisplayDelegate, template: AudioPlayerDisplayTemplate) -> Bool {
        return DispatchQueue.main.sync {
            guard let displayObject = delegate.audioPlayerDisplayDidRender(template: template) else { return false }
            
            replace(delegate: delegate, template: template)
            
            displayObject.rx.deallocated.subscribe({ [weak self] _ in
                self?.removeRenderedTemplate(delegate: delegate, template: template)
            }).disposed(by: disposeBag)
            return true
        }
    }
    
    func removeRenderedTemplate(delegate: AudioPlayerDisplayDelegate, template: AudioPlayerDisplayTemplate) {
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
    
    func hasRenderedDisplay(template: AudioPlayerDisplayTemplate) -> Bool {
        return renderingInfos.contains { $0.currentItem?.templateId == template.templateId }
    }
}
