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
import NuguUtils

import RxSwift

final class AudioPlayerDisplayManager {
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
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var audioPlayerStateObserver: Any?
    private var playSyncObserver: Any?
    
    private var disposeBag = DisposeBag()
    
    private var audioPlayerState: AudioPlayerState = .idle {
        didSet {
            guard currentItem != nil else { return }
            
            switch audioPlayerState {
            case .playing:
                playSyncManager.cancelTimer(property: playSyncProperty)
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
        
        // Observers
        addAudioPlayerAgentObserver(audioPlayerAgent)
        addPlaySyncObserver(playSyncManager)
    }
    
    deinit {
        if let audioPlayerStateObserver = audioPlayerStateObserver {
            notificationCenter.removeObserver(audioPlayerStateObserver)
        }
        
        if let playSyncObserver = playSyncObserver {
            notificationCenter.removeObserver(playSyncObserver)
        }
    }
}

// MARK: - AudioPlayerDisplayManageable

extension AudioPlayerDisplayManager {
    func display(payload: AudioPlayerPlayPayload, header: Downstream.Header) {
        guard let delegate = delegate else { return }
        guard let metaData = payload.audioItem.metadata,
            ((metaData["disableTemplate"] as? Bool) ?? false) == false else {
                return
        }
        guard let template = metaData["template"] as? [String: AnyHashable],
            let type = template["type"] as? String,
            let content = template["content"] as? [String: AnyHashable] else {
                log.error("Invalid metaData")
                return
        }

        // Seekable : when sourceType is "URL" and durationSec should be over than 0 (Followed by AudioPlayerInterface v1.4)
        let isSeekable = (payload.sourceType == .url)
            && (Int(content["durationSec"] as? String ?? "0") ?? 0 > 0)
        
        let item = AudioPlayerDisplayTemplate(
            header: header,
            type: type,
            payload: metaData,
            mediaPayload: AudioPlayerDisplayTemplate.MediaPayload(
                token: payload.audioItem.stream.token,
                playServiceId: payload.playServiceId,
                playStackControl: payload.playStackControl
            ),
            isSeekable: isSeekable
        )

        self.displayDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            let semaphore = DispatchSemaphore(value: 0)
            delegate.audioPlayerDisplayShouldRender(template: item) { [weak self] in
                defer { semaphore.signal() }
                guard let self = self else { return }
                guard let displayObject = $0 else { return }
                
                // Release sync when removed all of template(May be closed by user).
                Reactive(displayObject).deallocated
                    .observe(on: self.displayScheduler)
                    .subscribe({ [weak self] _ in
                        guard let self = self else { return }
                        
                        if self.currentItem?.templateId == item.templateId {
                            self.currentItem = nil
                            self.playSyncManager.stopPlay(dialogRequestId: item.dialogRequestId)
                        }
                    }).disposed(by: self.disposeBag)
                
                self.currentItem = item
                self.playSyncManager.startPlay(
                    property: self.playSyncProperty,
                    info: PlaySyncInfo(
                        playStackServiceId: item.mediaPayload.playStackControl?.playServiceId,
                        dialogRequestId: item.dialogRequestId,
                        messageId: item.templateId,
                        duration: NuguTimeInterval(seconds: 7)
                    )
                )
            }
            if semaphore.wait(timeout: .now() + .seconds(5)) == .timedOut {
                log.error("`audioPlayerDisplayShouldRender` completion block does not called")
            }
        }
    }
    
    func updateMetadata(payload: AudioPlayerUpdateMetadataPayload, playServiceId: String, header: Downstream.Header) {
        guard currentItem?.mediaPayload.playServiceId == playServiceId else { return }
        delegate?.audioPlayerDisplayShouldUpdateMetadata(payload: payload, header: header)
    }
    
    func showLyrics(playServiceId: String, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        guard let delegate = delegate,
            currentItem?.mediaPayload.playServiceId == playServiceId else {
                completion(false)
                return
        }
        delegate.audioPlayerDisplayShouldShowLyrics(completion: completion)
    }
    
    func hideLyrics(playServiceId: String, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
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
    
    func controlLyricsPage(payload: AudioPlayerDisplayControlPayload, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
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
        default:
            break
        }
    }
}

// MARK: - Observers

private extension AudioPlayerDisplayManager {
    func addAudioPlayerAgentObserver(_ object: AudioPlayerAgentProtocol) {
        audioPlayerStateObserver = object.observe(NuguAgentNotification.AudioPlayer.State.self, queue: nil) { [weak self] (notification) in
            self?.displayDispatchQueue.async { [weak self] in
                self?.audioPlayerState = notification.state
            }
        }
    }
    
    func addPlaySyncObserver(_ object: PlaySyncManageable) {
        playSyncObserver = object.observe(NuguCoreNotification.PlaySync.ReleasedProperty.self, queue: nil) { [weak self] (notification) in
            self?.displayDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard notification.property == self.playSyncProperty, let item = self.currentItem, item.templateId == notification.messageId else { return }
                
                self.currentItem = nil
                self.delegate?.audioPlayerDisplayDidClear(template: item)
            }
        }
    }
}
