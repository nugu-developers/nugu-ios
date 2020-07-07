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
    
    weak var delegate: AudioPlayerDisplayDelegate?
    
    private let audioPlayerPauseTimeout: DispatchTimeInterval
    private let playSyncManager: PlaySyncManageable
    
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
    func display(payload: AudioPlayerAgentMedia.Payload, messageId: String, dialogRequestId: String) {
        guard let metaData = payload.audioItem.metadata,
            ((metaData["disableTemplate"] as? Bool) ?? false) == false else {
                return
        }
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
            mediaPayload: payload
        )
        
        self.delegate?.audioPlayerDisplayShouldRender(template: item) { [weak self] in
            guard let self = self else { return }
            guard let displayObject = $0 else { return }

            // Release sync when removed all of template(May be closed by user).
            Reactive(displayObject).deallocated
                .observeOn(self.displayScheduler)
                .subscribe({ [weak self] _ in
                    guard let self = self else { return }
                    
                    if self.currentItem?.templateId == item.templateId {
                        self.currentItem = nil
                        self.playSyncManager.stopPlay(dialogRequestId: item.dialogRequestId)
                    }
                }).disposed(by: self.disposeBag)
            
            self.displayDispatchQueue.async { [weak self] in
                self?.currentItem = item
            }
        }
    }
    
    func updateMetadata(payload: Data, playServiceId: String) {
        guard currentItem?.mediaPayload.playServiceId == playServiceId else { return }
        delegate?.audioPlayerDisplayShouldUpdateMetadata(payload: payload)
    }
    
    func showLyrics(playServiceId: String, completion: @escaping (Bool) -> Void) {
        guard let delegate = delegate,
            currentItem?.mediaPayload.playServiceId == playServiceId else {
                completion(false)
                return
        }
        delegate.audioPlayerDisplayShouldShowLyrics(completion: completion)
    }
    
    func hideLyrics(playServiceId: String, completion: @escaping (Bool) -> Void) {
        guard let delegate = delegate,
            currentItem?.mediaPayload.playServiceId == playServiceId else {
                completion(false)
                return
        }
        delegate.audioPlayerDisplayShouldHideLyrics(completion: completion)
    }
    
    func isLyricsVisible(playServiceId: String, completion: @escaping (Bool) -> Void) {
        guard let delegate = delegate,
            currentItem?.mediaPayload.playServiceId == playServiceId else {
                completion(false)
                return
        }
        delegate.audioPlayerIsLyricsVisible(completion: completion)
    }
    
    func controlLyricsPage(payload: AudioPlayerDisplayControlPayload, completion: @escaping (Bool) -> Void) {
        guard let delegate = delegate,
            currentItem?.mediaPayload.playServiceId == payload.playServiceId else {
                completion(false)
                return
        }
        delegate.audioPlayerDisplayShouldControlLyricsPage(direction: payload.direction, completion: completion)
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
            self.delegate?.audioPlayerDisplayDidClear(template: item)
        }
    }
}
