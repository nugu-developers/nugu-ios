//
//  AudioPlayerDisplayManager.swift
//  NuguAgents
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

import NuguCore

import RxSwift

final class AudioPlayerDisplayManager: AudioPlayerDisplayManageable {
    private let playSyncProperty = PlaySyncProperty(layerType: .media, contextType: .display)
    
    private let displayDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.audio_player_display", qos: .userInitiated)
    private lazy var displayScheduler = SerialDispatchQueueScheduler(
        queue: displayDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.audio_player_display"
    )
    
    private let audioPlayerPauseTimeout: DispatchTimeInterval
    private let playSyncManager: PlaySyncManageable
    
    private var renderingInfos = [AudioPlayerDisplayRenderingInfo]()
    
    // Current display info
    private var currentItem: AudioPlayerDisplayTemplate?
    
    private var disposeBag = DisposeBag()
    
    private var audioPlayerState: AudioPlayerState = .idle {
        didSet {
            guard currentItem != nil else { return }
            
            switch audioPlayerState {
            case .playing:
                playSyncManager.cancelTimer(property: playSyncProperty)
            case .stopped, .finished:
                playSyncManager.endPlay(property: playSyncProperty)
            case .paused(let temporary):
                if temporary == false {
                    playSyncManager.startTimer(property: playSyncProperty, duration: audioPlayerPauseTimeout)
                }
            default:
                break
            }
        }
    }
    
    init(
        audioPlayerPauseTimeout: DispatchTimeInterval,
        audioPlayerAgent: AudioPlayerAgentProtocol,
        playSyncManager: PlaySyncManageable
    ) {
        self.audioPlayerPauseTimeout = audioPlayerPauseTimeout
        self.playSyncManager = playSyncManager
        
        audioPlayerAgent.add(delegate: self)
        playSyncManager.add(delegate: self)
    }
}

// MARK: - AudioPlayerDisplayManageable

extension AudioPlayerDisplayManager {
    func display(metaData: [String: AnyHashable], messageId: String, dialogRequestId: String, playStackServiceId: String?) {
        guard let template = metaData["template"] as? [String: AnyHashable],
            let type = template["type"] as? String else {
                log.error("Invalid metaData")
                return
        }
        
        let item = AudioPlayerDisplayTemplate(
            type: type,
            payload: metaData,
            templateId: messageId,
            dialogRequestId: dialogRequestId,
            playStackServiceId: playStackServiceId
        )
        
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            let rendered = self.renderingInfos
                .compactMap { $0.delegate }
                .map { self.setRenderedTemplate(delegate: $0, template: item) }
                .contains { $0 }
            if rendered == true {
                self.currentItem = item
                
                self.playSyncManager.startPlay(
                    property: self.playSyncProperty,
                    duration: .seconds(7),
                    playServiceId: item.playStackServiceId,
                    dialogRequestId: item.dialogRequestId
                )
            }
        }
    }
    
    func updateMetadata(payload: Data, playServiceId: String) {
        guard let info = renderingInfos.first(where: { $0.currentItem?.playStackServiceId == playServiceId }),
            let delegate = info.delegate else { return }
        delegate.audioPlayerDisplayShouldUpdateMetadata(payload: payload)
    }
    
    func showLyrics(playServiceId: String, completion: @escaping (Bool) -> Void) {
        guard let info = renderingInfos.first(where: { $0.currentItem?.playStackServiceId == playServiceId }),
            let delegate = info.delegate else {
                completion(false)
                return
        }
        delegate.audioPlayerDisplayShouldShowLyrics(completion: completion)
    }
    
    func hideLyrics(playServiceId: String, completion: @escaping (Bool) -> Void) {
        guard let info = renderingInfos.first(where: { $0.currentItem?.playStackServiceId == playServiceId }),
            let delegate = info.delegate else {
                completion(false)
                return
        }
        delegate.audioPlayerDisplayShouldHideLyrics(completion: completion)
    }
    
    func isLyricsVisible(playServiceId: String, completion: @escaping (Bool) -> Void) {
        guard let info = renderingInfos.first(where: { $0.currentItem?.playStackServiceId == playServiceId }),
            let delegate = info.delegate else {
                completion(false)
                return
        }
        delegate.audioPlayerIsLyricsVisible(completion: completion)
    }
    
    func controlLyricsPage(payload: AudioPlayerDisplayControlPayload, completion: @escaping (Bool) -> Void) {
        guard let info = renderingInfos.first(where: { $0.currentItem?.playStackServiceId == payload.playServiceId }),
            let delegate = info.delegate else {
                completion(false)
                return
        }
        delegate.audioPlayerDisplayShouldControlLyricsPage(direction: payload.direction, completion: completion)
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
    
    func notifyUserInteraction() {
        switch audioPlayerState {
        case .stopped, .finished:
            playSyncManager.resetTimer(property: playSyncProperty)
        case .paused(let temporary):
            if temporary == false {
                playSyncManager.startTimer(property: playSyncProperty, duration: audioPlayerPauseTimeout)
            }
        default:
            break
        }
    }
}

// MARK: - AudioPlayerAgentDelegate
extension AudioPlayerDisplayManager: AudioPlayerAgentDelegate {
    func audioPlayerAgentDidChange(state: AudioPlayerState, dialogRequestId: String) {
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.audioPlayerState = state
        }
    }
}

// MARK: - PlaySyncDelegate

extension AudioPlayerDisplayManager: PlaySyncDelegate {
    public func playSyncDidRelease(property: PlaySyncProperty, dialogRequestId: String) {
        displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard property == self.playSyncProperty, let item = self.currentItem, item.dialogRequestId == dialogRequestId else { return }
            
            self.currentItem = nil
            self.renderingInfos
                .filter({ (rederingInfo) -> Bool in
                    guard let template = rederingInfo.currentItem, let delegate = rederingInfo.delegate else { return false }
                    return self.removeRenderedTemplate(delegate: delegate, template: template)
                })
                .compactMap { $0.delegate }
                .forEach { $0.audioPlayerDisplayDidClear(template: item) }
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
        var displayResult: AnyObject?
        let semaphore = DispatchSemaphore(value: 0)
        delegate.audioPlayerDisplayShouldRender(template: template) {
            displayResult = $0
            semaphore.signal()
        }
        if semaphore.wait(timeout: .now() + .seconds(5)) == .timedOut {
            log.error("`audioPlayerDisplayShouldRender` completion block does not called")
        }
        guard let displayObject = displayResult else {
            return false
        }

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
    
    func removeRenderedTemplate(delegate: AudioPlayerDisplayDelegate, template: AudioPlayerDisplayTemplate) -> Bool {
        guard self.renderingInfos.contains(
            where: { $0.delegate === delegate && $0.currentItem?.templateId == template.templateId }
            ) else { return false }
        
        self.replace(delegate: delegate, template: nil)
        
        return true
    }
    
    func hasRenderedDisplay(template: AudioPlayerDisplayTemplate) -> Bool {
        return renderingInfos.contains { $0.currentItem?.templateId == template.templateId }
    }
}
