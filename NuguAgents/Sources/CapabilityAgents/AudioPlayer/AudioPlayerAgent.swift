//
//  AudioPlayerAgent.swift
//  NuguAgents
//
//  Created by MinChul Lee on 11/04/2019.
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

public final class AudioPlayerAgent: AudioPlayerAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .audioPlayer, version: "1.1")
    
    // AudioPlayerAgentProtocol
    public var offset: Int? {
        return currentMedia?.player.offset.truncatedSeconds
    }
    
    public var duration: Int? {
        return currentMedia?.player.duration.truncatedSeconds
    }
    
    public let audioPlayerPauseTimeout: DispatchTimeInterval
     
    // Private
    private let playSyncManager: PlaySyncManageable
    private let focusManager: FocusManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    private let audioPlayerDisplayManager: AudioPlayerDisplayManageable = AudioPlayerDisplayManager()
    private let delegates = DelegateSet<AudioPlayerAgentDelegate>()
    
    private let audioPlayerDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.audioplayer_agent", qos: .userInitiated)
    private lazy var audioPlayerScheduler = SerialDispatchQueueScheduler(
        queue: audioPlayerDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.audioplayer_agent_timer"
    )
    
    private var audioPlayerState: AudioPlayerState = .idle {
        didSet {
            if oldValue != audioPlayerState {
                log.info("AudioPlayerAgent state changed \(oldValue) -> \(audioPlayerState)")
            }
            
            guard let media = self.currentMedia else {
                log.error("AudioPlayerAgentMedia is nil")
                return
            }
            
            // progress report -> pause timer -> `PlaySyncState` -> `AudioPlayerAgentMedia` -> `AudioPlayerAgentDelegate`
            switch audioPlayerState {
            case .playing:
                startProgressReport()
                stopPauseTimeout()
                playSyncManager.startSync(
                    delegate: self,
                    dialogRequestId: media.dialogRequestId,
                    playServiceId: media.payload.playStackControl?.playServiceId
                )
            case .stopped, .finished:
                stopProgressReport()
                stopPauseTimeout()
                if media.cancelAssociation {
                    playSyncManager.releaseSyncImmediately(
                        dialogRequestId: media.dialogRequestId,
                        playServiceId: media.payload.playStackControl?.playServiceId
                    )
                } else {
                    playSyncManager.releaseSync(
                        delegate: self,
                        dialogRequestId: media.dialogRequestId,
                        playServiceId: media.payload.playStackControl?.playServiceId
                    )
                }
                currentMedia = nil
            case .paused:
                stopProgressReport()
                startPauseTimeout()
            default:
                break
            }
            
            // Notify delegates only if the agent's status changes.
            if oldValue != audioPlayerState {
                delegates.notify { delegate in
                    delegate.audioPlayerAgentDidChange(state: audioPlayerState, dialogRequestId: media.dialogRequestId)
                }
            }
        }
    }
    
    // Current play info
    private var currentMedia: AudioPlayerAgentMedia?
    
    private var playerIsMuted: Bool = false {
        didSet {
            currentMedia?.player.isMuted = playerIsMuted
        }
    }
    
    // ProgressReporter
    private var intervalReporter: Disposable?
    
    // Pause timeout
    private var pauseTimeout: Disposable?
    
    private lazy var disposeBag = DisposeBag()
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Play", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), preFetch: prefetchPlay, directiveHandler: handlePlay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Stop", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleStop),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Pause", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handlePause),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "UpdateMetadata", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleUpdateMetadata),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ShowLyrics", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleShowLyrics),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "HideRyrics", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleHideLyrics),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ControlLyricsPage", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleControlLyricsPage)
    ]
    
    public init(
        focusManager: FocusManageable,
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable,
        audioPlayerPauseTimeout: DispatchTimeInterval = .milliseconds(600000)
    ) {
        self.focusManager = focusManager
        self.upstreamDataSender = upstreamDataSender
        self.playSyncManager = playSyncManager
        self.directiveSequencer = directiveSequencer
        self.audioPlayerPauseTimeout = audioPlayerPauseTimeout
        
        contextManager.add(provideContextDelegate: self)
        focusManager.add(channelDelegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        
        audioPlayerDisplayManager.playSyncManager = playSyncManager
    }

    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        currentMedia?.player.stop()
    }
}

// MARK: - AudioPlayerAgent + AudioPlayerAgentProtocol

public extension AudioPlayerAgent {
    func add(delegate: AudioPlayerAgentDelegate) {
        delegates.add(delegate)
    }
    
    func remove(delegate: AudioPlayerAgentDelegate) {
        delegates.remove(delegate)
    }
    
    func play() {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.currentMedia != nil else { return }
            
            switch self.audioPlayerState {
            case .paused:
                self.resume()
            default:
                log.debug("Skip, not paused state.")
            }
        }
    }
    
    func stop() {
        stop(cancelAssociation: true)
    }
    
    @discardableResult func next(completion: ((StreamDataState) -> Void)?) -> String {
        let dialogRequestId = TimeUUID().hexString
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let media = self.currentMedia else { return }
            
            self.sendPlayEvent(media: media, typeInfo: .nextCommandIssued, dialogRequestId: dialogRequestId, completion: completion)
        }
        return dialogRequestId
    }
    
    @discardableResult func prev(completion: ((StreamDataState) -> Void)?) -> String {
        let dialogRequestId = TimeUUID().hexString
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let media = self.currentMedia else { return }
            
            self.sendPlayEvent(media: media, typeInfo: .previousCommandIssued, dialogRequestId: dialogRequestId, completion: completion)
        }
        return dialogRequestId
    }
    
    func pause() {
        audioPlayerDispatchQueue.async { [weak self] in
            self?.currentMedia?.pauseReason = .user
            self?.currentMedia?.player.pause()
        }
    }
    
    func favorite(isOn: Bool) {
        guard let media = currentMedia else { return }
        
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.sendSettingsEvent(media: media, typeInfo: .favoriteCommandIssued(isOn: isOn))
        }
    }
    
    func `repeat`(mode: AudioPlayerDisplayRepeat) {
        guard let media = currentMedia else { return }
        
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.sendSettingsEvent(media: media, typeInfo: .repeatCommandIssued(mode: mode))
        }
    }
    
    func shuffle(isOn: Bool) {
        guard let media = currentMedia else { return }
        
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.sendSettingsEvent(media: media, typeInfo: .shuffleCommandIssued(isOn: isOn))
        }
    }
    
    func seek(to offset: Int) {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.currentMedia?.player.seek(to: NuguTimeInterval(seconds: offset))
        }
    }
    
    func add(displayDelegate: AudioPlayerDisplayDelegate) {
        audioPlayerDisplayManager.add(delegate: displayDelegate)
    }
    
    func remove(displayDelegate: AudioPlayerDisplayDelegate) {
        audioPlayerDisplayManager.remove(delegate: displayDelegate)
    }
    
    func stopRenderingTimer(templateId: String) {
        audioPlayerDisplayManager.stopRenderingTimer(templateId: templateId)
    }
}

// MARK: - FocusChannelDelegate

extension AudioPlayerAgent: FocusChannelDelegate {
    public func focusChannelPriority() -> FocusChannelPriority {
        return .content
    }
    
    public func focusChannelDidChange(focusState: FocusState) {
        log.info("\(focusState) \(audioPlayerState)")
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch (focusState, self.audioPlayerState) {
            case (.foreground, let playerState) where [.idle, .stopped, .finished].contains(playerState):
                self.currentMedia?.player.play()
            // Directive 에 의한 Pause 인경우 재생하지 않음.
            case (.foreground, .paused):
                if self.currentMedia?.pauseReason != .user {
                    self.currentMedia?.player.resume()
                }
            // Foreground. playing 무시
            case (.foreground, _):
                break
            case (.background, .playing):
                self.currentMedia?.pauseReason = .focus
                self.currentMedia?.player.pause()
            // background. idle, pause, stopped, finished 무시
            case (.background, _):
                break
            case (.nothing, .playing),
                 (.nothing, .paused):
                self.stop(cancelAssociation: false)
            // none. idle/stopped/finished 무시
            case (.nothing, _):
                break
            }
        }
    }
}

// MARK: - MediaPlayerDelegate

extension AudioPlayerAgent: MediaPlayerDelegate {
    public func mediaPlayerDidChange(state: MediaPlayerState) {
        audioPlayerDispatchQueue.async { [weak self] in
            log.info("\(state)")
            guard let self = self else { return }
            guard let media = self.currentMedia else { return }
            
            // `AudioPlayerState` -> Event -> `FocusState`
            switch state {
            case .start:
                self.audioPlayerState = .playing
                self.sendPlayEvent(media: media, typeInfo: .playbackStarted)
            case .resume:
                self.audioPlayerState = .playing
                if media.pauseReason != .focus {
                    self.sendPlayEvent(media: media, typeInfo: .playbackResumed)
                }
            case .finish:
                self.audioPlayerState = .finished
                self.sendPlayEvent(media: media, typeInfo: .playbackFinished) { [weak self] state in
                    // Release focus when stream finished.
                    self?.audioPlayerDispatchQueue.async { [weak self] in
                        guard let self = self else { return }
                        
                        switch state {
                        case .finished where self.currentMedia == nil:
                            self.releaseFocusIfNeeded()
                        case .error:
                            self.releaseFocusIfNeeded()
                        default:
                            break
                        }
                    }
                }
            case .pause:
                if media.pauseReason != .focus {
                    self.audioPlayerState = .paused(temporary: false)
                    self.sendPlayEvent(media: media, typeInfo: .playbackPaused)
                } else {
                    self.audioPlayerState = .paused(temporary: true)
                }
            case .stop:
                self.audioPlayerState = .stopped
                self.sendPlayEvent(media: media, typeInfo: .playbackStopped)
                self.releaseFocusIfNeeded()
            case .bufferUnderrun, .bufferRefilled:
                break
            case .error(let error):
                log.error("\(state) \(error)")
                self.audioPlayerState = .stopped
                self.sendPlayEvent(media: media, typeInfo: .playbackFailed(error: error))
                self.releaseFocusIfNeeded()
            }
        }
    }
}

// MARK: - ContextInfoDelegate

extension AudioPlayerAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: (ContextInfo?) -> Void) {
        var payload: [String: Any?] = [
            "version": capabilityAgentProperty.version,
            "playerActivity": audioPlayerState.playerActivity,
            // This is a mandatory in Play kit.
            "offsetInMilliseconds": (offset ?? 0) * 1000,
            "token": currentMedia?.payload.audioItem.stream.token
        ]
        if let duration = duration {
            payload["durationInMilliseconds"] = duration * 1000
        }
        completion(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
    }
}

// MARK: - PlaySyncDelegate

extension AudioPlayerAgent: PlaySyncDelegate {
    public func playSyncIsDisplay() -> Bool {
        return false
    }
    
    public func playSyncDuration() -> PlaySyncDuration {
        return .short
    }
    
    public func playSyncDidChange(state: PlaySyncState, dialogRequestId: String) {
        log.info("\(state)")
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let media = self.currentMedia, media.dialogRequestId == dialogRequestId else { return }
            
            if [.releasing, .released].contains(state) {
                self.stop(cancelAssociation: false)
            }
        }
    }
}

// MARK: - SpeakerVolumeDelegate

extension AudioPlayerAgent: SpeakerVolumeDelegate {
    public func speakerVolumeType() -> SpeakerVolumeType {
        return .nugu
    }
    
    public func speakerVolumeIsMuted() -> Bool {
        return playerIsMuted
    }
   
    public func speakerVolumeShouldChange(muted: Bool) -> Bool {
        playerIsMuted = muted
        return true
    }
}

// MARK: - Private (Directive)

private extension AudioPlayerAgent {
    func prefetchPlay() -> HandleDirective {
        return { [weak self] directive, completion in
            self?.audioPlayerDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                completion(
                    Result<Void, Error>(catching: {
                        guard let data = directive.payload.data(using: .utf8) else {
                            throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
                        }
                        let payload = try JSONDecoder().decode(AudioPlayerAgentMedia.Payload.self, from: data)
                        guard case .url = payload.sourceType else {
                            throw HandleDirectiveError.handleDirectiveError(message: "Not supported sourceType")
                        }
                        
                        switch self.currentMedia {
                        case .some(let media) where media.payload.audioItem.stream.token == payload.audioItem.stream.token:
                            // Resume and seek
                            self.currentMedia = AudioPlayerAgentMedia(
                                dialogRequestId: directive.header.dialogRequestId,
                                player: media.player,
                                payload: payload
                            )
                            
                            media.player.seek(to: NuguTimeInterval(seconds: payload.audioItem.stream.offset))
                        case .some:
                            self.stopSilently()
                            try self.setMediaPlayer(dialogRequestId: directive.header.dialogRequestId, payload: payload)
                        case .none:
                            // Set mediaplayer
                            try self.setMediaPlayer(dialogRequestId: directive.header.dialogRequestId, payload: payload)
                        }
                        self.playSyncManager.prepareSync(
                            delegate: self,
                            dialogRequestId: directive.header.dialogRequestId,
                            playServiceId: payload.playStackControl?.playServiceId
                        )
                        
                        if let metaData = payload.audioItem.metadata,
                            ((metaData["disableTemplate"] as? Bool) ?? false) == false {
                            self.audioPlayerDisplayManager.display(
                                metaData: metaData,
                                messageId: directive.header.messageId,
                                dialogRequestId: directive.header.dialogRequestId,
                                playStackServiceId: payload.playStackControl?.playServiceId
                            )
                        }
                    }).flatMapError({ (error) -> Result<Void, Error> in
                        if let media = self.currentMedia {
                            self.sendPlayEvent(media: media, typeInfo: .playbackFailed(error: error))
                        }
                        self.releaseFocusIfNeeded()
                        return .failure(error)
                    })
                )
            }
        }
    }
    
   func handlePlay() -> HandleDirective {
        return { [weak self] _, completion in
            self?.resume()
            completion(.success(()))
        }
    }
    
   func handleStop() -> HandleDirective {
        return { [weak self] _, completion in
            self?.stop(cancelAssociation: true)
            completion(.success(()))
        }
    }
    
   func handlePause() -> HandleDirective {
        return { [weak self] _, completion in
            self?.pause()
            completion(.success(()))
        }
    }
    
    func handleUpdateMetadata() -> HandleDirective {
        return { [weak self] directive, completion in
            completion(
                Result { [weak self] in
                    guard let self = self else { return }
                    guard let data = directive.payload.data(using: .utf8),
                        let payloadAsDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                        let playServiceId = payloadAsDictionary["playServiceId"] as? String else {
                            throw HandleDirectiveError.handleDirectiveError(message: "Unknown template")
                    }
                    self.audioPlayerDisplayManager.updateMetadata(payload: directive.payload, playServiceId: playServiceId)
            })
        }
    }
    
    func handleShowLyrics() -> HandleDirective {
        return { [weak self] directive, completion in
            completion(
                Result { [weak self] in
                    guard let self = self else { return }
                    guard let data = directive.payload.data(using: .utf8),
                        let payloadAsDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                        let playServiceId = payloadAsDictionary["playServiceId"] as? String else {
                            throw HandleDirectiveError.handleDirectiveError(message: "Unknown template")
                    }
                    
                    let isSuccess = self.audioPlayerDisplayManager.showLylics(playServiceId: playServiceId)
                    
                    self.sendLyricsEvent(
                        playServiceId: playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId,
                        typeInfo: isSuccess ? .showLyricsSucceeded : .showLyricsFailed
                    )
            })
        }
    }
    
    func handleHideLyrics() -> HandleDirective {
        return { [weak self] directive, completion in
            completion(
                Result { [weak self] in
                    guard let self = self else { return }
                    guard let data = directive.payload.data(using: .utf8),
                        let payloadAsDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                        let playServiceId = payloadAsDictionary["playServiceId"] as? String else {
                            throw HandleDirectiveError.handleDirectiveError(message: "Unknown template")
                    }
                    
                    let isSuccess = self.audioPlayerDisplayManager.hideLylics(playServiceId: playServiceId)
                    
                    self.sendLyricsEvent(
                        playServiceId: playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId,
                        typeInfo: isSuccess ? .hideLyricsSucceeded : .hideLyricsFailed
                    )
            })
        }
    }
    
    func handleControlLyricsPage() -> HandleDirective {
        return { [weak self] directive, completion in
            completion(
                Result { [weak self] in
                    guard let self = self else { return }
                    guard let data = directive.payload.data(using: .utf8) else {
                            throw HandleDirectiveError.handleDirectiveError(message: "Unknown template")
                    }
                    
                    let payload = try JSONDecoder().decode(AudioPlayerDisplayControlPayload.self, from: data)
                    let isSuccess = self.audioPlayerDisplayManager.controlLylicsPage(payload: payload)
                    
                    self.sendLyricsEvent(
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId,
                        typeInfo: isSuccess ? .controlLyricsPageSucceeded(direction: payload.direction) : .controlLyricsPageFailed(direction: payload.direction)
                    )
            })
        }
    }
    

    func resume() {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.currentMedia != nil else { return }
            self.currentMedia?.pauseReason = .nothing
            self.focusManager.requestFocus(channelDelegate: self)
        }
    }
        
    func stop(cancelAssociation: Bool) {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self, let media = self.currentMedia else { return }
            
            self.currentMedia?.cancelAssociation = cancelAssociation
            media.player.stop()
        }
    }
    
    /// Stop mediaplayer
    func stopSilently() {
        guard let media = self.currentMedia else { return }
            
        // `AudioPlayerState` -> Event
        switch self.audioPlayerState {
        case .playing, .paused:
            media.player.delegate = nil
            media.player.stop()
            self.audioPlayerState = .stopped
            self.sendPlayEvent(media: media, typeInfo: .playbackStopped)
        case .idle, .stopped, .finished:
            return
        }
    }
}

// MARK: - Private (Event)

private extension AudioPlayerAgent {
    func sendPlayEvent(
        media: AudioPlayerAgentMedia,
        typeInfo: PlayEvent.TypeInfo,
        dialogRequestId: String = TimeUUID().hexString,
        completion: ((StreamDataState) -> Void)? = nil
    ) {
        upstreamDataSender.sendEvent(
            PlayEvent(
                token: media.payload.audioItem.stream.token,
                offsetInMilliseconds: (offset ?? 0) * 1000, // This is a mandatory in Play kit.
                playServiceId: media.payload.playServiceId,
                typeInfo: typeInfo
            ).makeEventMessage(agent: self, dialogRequestId: dialogRequestId, referrerDialogRequestId: media.dialogRequestId),
            completion: completion
        )
    }
    
    func sendSettingsEvent(
        media: AudioPlayerAgentMedia,
        typeInfo: SettingsEvent.TypeInfo,
        completion: ((StreamDataState) -> Void)? = nil
    ) {
        upstreamDataSender.sendEvent(
            SettingsEvent(
                playServiceId: media.payload.playServiceId,
                typeInfo: typeInfo
            ).makeEventMessage(agent: self, referrerDialogRequestId: media.dialogRequestId),
            completion: completion
        )
    }
    
    func sendLyricsEvent(
        playServiceId: String,
        referrerDialogRequestId: String,
        typeInfo: LyricsEvent.TypeInfo,
        completion: ((StreamDataState) -> Void)? = nil
    ) {
        upstreamDataSender.sendEvent(
            LyricsEvent(
                playServiceId: playServiceId,
                typeInfo: typeInfo
            ).makeEventMessage(agent: self, referrerDialogRequestId: referrerDialogRequestId),
            completion: completion
        )
    }
}

// MARK: - Private(FocusManager)

private extension AudioPlayerAgent {
    func releaseFocusIfNeeded() {
        guard [.idle, .stopped, .finished].contains(self.audioPlayerState) else {
            log.info("Not permitted in current state, \(audioPlayerState)")
            return
        }
        focusManager.releaseFocus(channelDelegate: self)
    }
}

// MARK: - Private (Timer)

private extension AudioPlayerAgent {
    func startProgressReport() {
        stopProgressReport()
        guard let media = currentMedia else { return }
        let delayReportTime = media.payload.audioItem.stream.delayReportTime ?? -1
        let intervalReportTime = media.payload.audioItem.stream.intervalReportTime ?? -1
        guard delayReportTime > 0 || intervalReportTime > 0 else { return }
        
        var lastOffset: Int = 0
        
        intervalReporter = Observable<Int>
            .interval(.seconds(1), scheduler: audioPlayerScheduler)
            .map({ [weak self] (_) -> Int in
                return self?.currentMedia?.player.offset.truncatedSeconds ?? -1
            })
            .filter { $0 > 0 }
            .filter { $0 != lastOffset}
            .subscribe(onNext: { [weak self] (offset) in
                log.debug("offset: \(offset)")
                if delayReportTime > 0, offset == delayReportTime {
                    self?.sendPlayEvent(media: media, typeInfo: .progressReportDelayElapsed)
                }
                if intervalReportTime > 0, offset % intervalReportTime == 0 {
                    self?.sendPlayEvent(media: media, typeInfo: .progressReportIntervalElapsed)
                }
                lastOffset = offset
            })
        
        intervalReporter?.disposed(by: disposeBag)
    }
    
    func stopProgressReport() {
        intervalReporter?.dispose()
    }
    
    func startPauseTimeout() {
        stopPauseTimeout()
        
        guard audioPlayerPauseTimeout != .never else {
            return
        }
        
        pauseTimeout = Observable<Int>
            .timer(audioPlayerPauseTimeout, scheduler: audioPlayerScheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.stop(cancelAssociation: false)
            })
        pauseTimeout?.disposed(by: disposeBag)
    }
    
    func stopPauseTimeout() {
        pauseTimeout?.dispose()
    }
}

// MARK: - Private (Media)

private extension AudioPlayerAgent {
    /// set mediaplayer
    func setMediaPlayer(dialogRequestId: String, payload: AudioPlayerAgentMedia.Payload) throws {
        let mediaPlayer = MediaPlayer()
        mediaPlayer.delegate = self
        
        self.currentMedia = AudioPlayerAgentMedia(
            dialogRequestId: dialogRequestId,
            player: mediaPlayer,
            payload: payload
        )
        
        try mediaPlayer.setSource(
            url: payload.audioItem.stream.url,
            offset: NuguTimeInterval(seconds: payload.audioItem.stream.offset)
        )
        
        mediaPlayer.isMuted = playerIsMuted
    }
}
