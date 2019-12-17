//
//  AudioPlayerAgent.swift
//  NuguCore
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

import NuguInterface

import RxSwift

final public class AudioPlayerAgent: AudioPlayerAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .audioPlayer, version: "1.0")
    
    private let audioPlayerDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.audioplayer_agent", qos: .userInitiated)
    private lazy var audioPlayerScheduler = SerialDispatchQueueScheduler(
        queue: audioPlayerDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.audioplayer_agent_timer"
    )
    
    private let focusManager: FocusManageable
    private let channelPriority: FocusChannelPriority
    private let mediaPlayerFactory: MediaPlayerFactory
    private let upstreamDataSender: UpstreamDataSendable
    private let playSyncManager: PlaySyncManageable
    
    private let audioPlayerDisplayManager: AudioPlayerDisplayManageable = AudioPlayerDisplayManager()
    
    // AudioPlayerAgentProtocol
    private let delegates = DelegateSet<AudioPlayerAgentDelegate>()
    
    public var offset: Int? {
        return currentMedia?.player.offset.truncatedSeconds
    }
    
    public var duration: Int? {
        return currentMedia?.player.duration.truncatedSeconds
    }
    
    private var focusState: FocusState = .nothing
    private var audioPlayerState: AudioPlayerState = .idle {
        didSet {
            log.info("\(oldValue) \(audioPlayerState)")
            
            guard oldValue != audioPlayerState else { return }
            
            // Progress Report
            switch audioPlayerState {
            case .playing:
                startProgressReport()
            default:
                stopProgressReport()
            }
            
            // Release Focus
            switch audioPlayerState {
            case .idle, .stopped, .finished:
                stopPauseTimeout()
                if let media = currentMedia {
                    self.currentMedia = nil
                    playSyncManager.releaseSync(delegate: self, dialogRequestId: media.dialogRequestId, playServiceId: media.payload.playStackControl?.playServiceId)
                }
            case .playing:
                stopPauseTimeout()
                if let media = currentMedia {
                    playSyncManager.startSync(delegate: self, dialogRequestId: media.dialogRequestId, playServiceId: media.payload.playStackControl?.playServiceId)
                }
            case .paused:
                startPauseTimeout()
            }
            
            delegates.notify { delegate in
                delegate.audioPlayerAgentDidChange(state: audioPlayerState)
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
    
    public init(
        focusManager: FocusManageable,
        channelPriority: FocusChannelPriority,
        mediaPlayerFactory: MediaPlayerFactory,
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable
    ) {
        log.info("")
        
        self.focusManager = focusManager
        self.channelPriority = channelPriority
        self.mediaPlayerFactory = mediaPlayerFactory
        self.upstreamDataSender = upstreamDataSender
        self.playSyncManager = playSyncManager
        
        audioPlayerDisplayManager.playSyncManager = playSyncManager
    }

    deinit {
        log.info("")
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
        guard let media = self.currentMedia else { return }
        
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            switch self.audioPlayerState {
            case .paused:
                self.resume()
            default:
                self.sendEvent(media: media, typeInfo: .playCommandIssued)
            }
        }
    }
    
    private func resume() {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.currentMedia != nil else { return }
            self.currentMedia?.blockResume = false
            self.focusManager.requestFocus(channelDelegate: self)
        }
    }
    
    func stop() {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self, let media = self.currentMedia else { return }
            
            media.player.stop()
            self.playSyncManager.releaseSyncImmediately(dialogRequestId: media.dialogRequestId, playServiceId: media.payload.playStackControl?.playServiceId)
        }
    }
    
    /// Stop mediaplayer
    private func stopSilently() {
        guard let media = self.currentMedia else { return }
            
        switch self.audioPlayerState {
        case .playing, .paused:
            media.player.delegate = nil
            media.player.stop()
            self.sendEvent(media: media, typeInfo: .playbackStopped)
            self.audioPlayerState = .stopped
        case .idle, .stopped, .finished:
            return
        }
    }
    
    func next() {
        guard let media = self.currentMedia else { return }
        
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.sendEvent(media: media, typeInfo: .nextCommandIssued)
        }
    }
    
    func prev() {
        guard let media = self.currentMedia else { return }
        
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.sendEvent(media: media, typeInfo: .previousCommandIssued)
        }
    }
    
    func pause() {
        audioPlayerDispatchQueue.async { [weak self] in
            self?.currentMedia?.blockResume = true
            self?.currentMedia?.player.pause()
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

// MARK: - HandleDirectiveDelegate

extension AudioPlayerAgent: HandleDirectiveDelegate {
    public func handleDirectiveTypeInfos() -> DirectiveTypeInfos {
        return DirectiveTypeInfo.allDictionaryCases
    }
    
    public func handleDirectivePrefetch(
        _ directive: Downstream.Directive,
        completionHandler: @escaping (Result<Void, Error>) -> Void) {
        log.info("\(directive.header.type)")
        
        switch directive.header.type {
        case DirectiveTypeInfo.play.type:
            prefetchPlay(directive: directive, completionHandler: completionHandler)
        default:
            completionHandler(.success(()))
        }
    }
    
    public func handleDirective(
        _ directive: Downstream.Directive,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        log.info("\(directive.header.type)")
        
        let result = Result<DirectiveTypeInfo, Error>(catching: {
            guard let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Unknown directive")
            }
            
            return directiveTypeInfo
        }).map({ (typeInfo) -> Void in
            switch typeInfo {
            case .play:
                resume()
            case .stop:
                stop()
            case .pause:
                pause()
            }
        })
            
        completionHandler(result)
    }
}

// MARK: - FocusChannelDelegate

extension AudioPlayerAgent: FocusChannelDelegate {
    public func focusChannelPriority() -> FocusChannelPriority {
        return channelPriority
    }
    
    public func focusChannelDidChange(focusState: FocusState) {
        log.info("\(focusState) \(audioPlayerState)")
        self.focusState = focusState
        
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch (focusState, self.audioPlayerState) {
            case (.foreground, let playerState) where [.idle, .stopped, .finished].contains(playerState):
                self.currentMedia?.player.play()
            case (.foreground, .paused):
                // Directive 에 의한 Pause 인경우 재생하지 않음.
                if let media = self.currentMedia, media.blockResume == false {
                    media.player.resume()
                }
            // Foreground. playing 무시
            case (.foreground, _):
                break
            case (.background, .playing):
                self.currentMedia?.player.pause()
            // background. idle, pause, stopped, finished 무시
            case (.background, _):
                break
            case (.nothing, let playerState) where [.playing, .paused].contains(playerState):
                self.currentMedia?.player.stop()
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
            
            switch state {
            case .start:
                self.sendEvent(media: media, typeInfo: .playbackStarted)
                self.audioPlayerState = .playing
            case .resume:
                self.sendEvent(media: media, typeInfo: .playbackResumed)
                self.audioPlayerState = .playing
            case .finish:
                // Release focus after receiving directive
                self.sendEvent(media: media, typeInfo: .playbackFinished) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let directive):
                        let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self)
                        switch directiveTypeInfo {
                        case .play:
                            break
                        default:
                            self.releaseFocusIfNeeded()
                        }
                    case .failure:
                        self.releaseFocusIfNeeded()
                    }
                }
                self.audioPlayerState = .finished
            case .pause:
                self.sendEvent(media: media, typeInfo: .playbackPaused)
                self.audioPlayerState = .paused
            case .stop:
                self.sendEvent(media: media, typeInfo: .playbackStopped)
                self.audioPlayerState = .stopped
                self.releaseFocusIfNeeded()
            case .bufferUnderrun, .bufferRefilled:
                break
            case .error(let error):
                log.error("\(state) \(error)")
                self.sendEvent(media: media, typeInfo: .playbackFailed(error: error))
                self.audioPlayerState = .stopped
                self.releaseFocusIfNeeded()
            }
        }
    }
}

// MARK: - ContextInfoDelegate

extension AudioPlayerAgent: ContextInfoDelegate {
    public func contextInfoRequestContext() -> ContextInfo? {
        var payload: [String: Any?] = [
            "version": capabilityAgentProperty.version,
            "playerActivity": audioPlayerState.rawValue,
            // This is a mandatory in Play kit.
            "offsetInMilliseconds": (offset ?? 0) * 1000,
            "token": currentMedia?.payload.audioItem.stream.token
        ]
        if let duration = duration {
            payload["durationInMilliseconds"] = duration * 1000
        }
        return ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 })
    }
}

// MARK: - PlaySyncDelegate

extension AudioPlayerAgent: PlaySyncDelegate {
    public func playSyncIsDisplay() -> Bool {
        return false
    }
    
    public func playSyncDuration() -> DisplayTemplate.Duration {
        return .short
    }
    
    public func playSyncDidChange(state: PlaySyncState, dialogRequestId: String) {
        log.info("\(state)")
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            if case .released = state,
                let media = self.currentMedia, media.dialogRequestId == dialogRequestId {
                self.stopSilently()
                self.currentMedia = nil
                self.releaseFocusIfNeeded()
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
    func prefetchPlay(directive: Downstream.Directive, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            let result = Result<Void, Error>(catching: {
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
                self.playSyncManager.prepareSync(delegate: self, dialogRequestId: directive.header.dialogRequestId, playServiceId: payload.playStackControl?.playServiceId)
                
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
                    self.sendEvent(media: media, typeInfo: .playbackFailed(error: error))
                }
                self.releaseFocusIfNeeded()
                return .failure(error)
            })
            
            completionHandler(result)
        }
    }
}

// MARK: - Private (Event)

private extension AudioPlayerAgent {
    func sendEvent(media: AudioPlayerAgentMedia, typeInfo: Event.TypeInfo, resultHandler: ((Result<Downstream.Directive, Error>) -> Void)? = nil) {
        sendEvent(
            Event(
                token: media.payload.audioItem.stream.token,
                offsetInMilliseconds: (offset ?? 0) * 1000, // This is a mandatory in Play kit.
                playServiceId: media.payload.playServiceId,
                typeInfo: typeInfo
            ),
            context: contextInfoRequestContext(),
            dialogRequestId: TimeUUID().hexString,
            by: upstreamDataSender,
            resultHandler: resultHandler
        )
    }
}

// MARK: - Private(FocusManager)

private extension AudioPlayerAgent {
    func releaseFocusIfNeeded() {
        guard focusState != .nothing else { return }
        guard [.idle, .stopped, .finished].contains(self.audioPlayerState) else { return }
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
            .do(onNext: { [weak self] (offset) in
                log.debug(offset)
                if delayReportTime > 0, offset == delayReportTime {
                    self?.sendEvent(media: media, typeInfo: .progressReportDelayElapsed)
                }
                if intervalReportTime > 0, offset % intervalReportTime == 0 {
                    self?.sendEvent(media: media, typeInfo: .progressReportIntervalElapsed)
                }
                lastOffset = offset
            })
            .subscribe()
        
        intervalReporter?.disposed(by: disposeBag)
    }
    
    func stopProgressReport() {
        intervalReporter?.dispose()
    }
    
    func startPauseTimeout() {
        stopPauseTimeout()
        pauseTimeout = Completable.create { [weak self] event -> Disposable in
            if let self = self, let media = self.currentMedia {
                self.playSyncManager.releaseSyncImmediately(dialogRequestId: media.dialogRequestId, playServiceId: media.payload.playStackControl?.playServiceId)
            }
            event(.completed)
            return Disposables.create()
        }
        .delaySubscription(NuguConfiguration.audioPlayerPauseTimeout, scheduler: audioPlayerScheduler)
        .subscribe()
        
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
        let mediaPlayer = self.mediaPlayerFactory.makeMediaPlayer()
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
