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
    
    public var focusManager: FocusManageable!
    public var channel: FocusChannelConfigurable!
    public var mediaPlayerFactory: MediaPlayableFactory!
    public var messageSender: MessageSendable!
    public var playSyncManager: PlaySyncManageable! {
        didSet {
            audioPlayerDisplayManager.playSyncManager = playSyncManager
        }
    }
    
    private let audioPlayerDisplayManager: AudioPlayerDisplayManageable = AudioPlayerDisplayManager()
    
    // AudioPlayerAgentProtocol
    private let delegates = DelegateSet<AudioPlayerAgentDelegate>()
    public var offset: Int? {
        return currentMedia?.player.offset
    }
    public var duration: Int? {
        return currentMedia?.player.duration
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
                    playSyncManager.releaseSync(delegate: self, dialogRequestId: media.dialogRequestId, playServiceId: media.payload.playServiceId)
                }
            case .playing:
                stopPauseTimeout()
                if let media = currentMedia {
                    playSyncManager.startSync(delegate: self, dialogRequestId: media.dialogRequestId, playServiceId: media.payload.playServiceId)
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
    private var currentMedia: AudioPlayerAgentMedia? {
        didSet {
            if currentMedia == nil {
                releaseFocus()
            }
        }
    }
    
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
    
    public init() {
        log.info("")
    }

    deinit {
        log.info("")
    }
}

// MARK: - AudioPlayerAgentProtocol

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
            switch self.audioPlayerState {
            case .paused:
                self.resume()
            default:
                self.sendEvent(typeInfo: .playCommandIssued)
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
            self.playSyncManager.releaseSyncImmediately(dialogRequestId: media.dialogRequestId, playServiceId: media.payload.playServiceId)
        }
    }
    
    /// Stop mediaplayer
    private func stopSilently() {
        guard let media = self.currentMedia else { return }
            
        switch self.audioPlayerState {
        case .playing, .paused:
            media.player.delegate = nil
            media.player.stop()
            self.sendEvent(typeInfo: .playbackStopped)
            self.audioPlayerState = .stopped
        case .idle, .stopped, .finished:
            return
        }
    }
    
    func next() {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.sendEvent(typeInfo: .nextCommandIssued)
        }
    }
    
    func prev() {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.sendEvent(typeInfo: .previousCommandIssued)
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
            self.currentMedia?.player.seek(to: offset)
        }
    }
    
    func add(displayDelegate: AudioPlayerDisplayDelegate) {
        audioPlayerDisplayManager.add(delegate: displayDelegate)
    }
    
    func remove(displayDelegate: AudioPlayerDisplayDelegate) {
        audioPlayerDisplayManager.remove(delegate: displayDelegate)
    }
    
    func clearDisplay(displayDelegate: AudioPlayerDisplayDelegate) {
        audioPlayerDisplayManager.clearDisplay(delegate: displayDelegate)
    }
}

// MARK: - HandleDirectiveDelegate

extension AudioPlayerAgent: HandleDirectiveDelegate {
    public func handleDirectiveTypeInfos() -> DirectiveTypeInfos {
        return DirectiveTypeInfo.allDictionaryCases
    }
    
    public func handleDirectivePrefetch(
        _ directive: DirectiveProtocol,
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
        _ directive: DirectiveProtocol,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        log.info("\(directive.header.type)")
        
        let result = Result<DirectiveTypeInfo, Error> (catching: {
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
    public func focusChannelConfiguration() -> FocusChannelConfigurable {
        return channel
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
            
            if let eventTypeInfo = state.eventTypeInfo {
                self.sendEvent(typeInfo: eventTypeInfo)
            }
            
            switch state {
            case .start, .resume:
                self.audioPlayerState = .playing
            case .finish:
                self.audioPlayerState = .finished
            case .pause:
                self.audioPlayerState = .paused
            case .stop:
                self.audioPlayerState = .stopped
            case .bufferUnderrun, .bufferRefilled:
                break
            case .error(let error):
                log.error("\(state) \(error)")
                self.audioPlayerState = .stopped
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
    func prefetchPlay(directive: DirectiveProtocol, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            let result = Result<Void, Error> (catching: {
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
                    self.currentMedia = AudioPlayerAgentMedia(dialogRequestId: directive.header.dialogRequestID, player: media.player, payload: payload)
                    media.player.seek(to: payload.audioItem.stream.offset)
                case .some:
                    self.stopSilently()
                    try self.setMediaPlayer(dialogRequestId: directive.header.dialogRequestID, payload: payload)
                case .none:
                    // Set mediaplayer
                    try self.setMediaPlayer(dialogRequestId: directive.header.dialogRequestID, payload: payload)
                }
                
                if let metaData = payload.audioItem.metadata,
                    ((metaData["disableTemplate"] as? Bool) ?? false) == false {
                    self.audioPlayerDisplayManager.display(
                        metaData: metaData,
                        messageId: directive.header.messageID,
                        dialogRequestId: directive.header.dialogRequestID,
                        playServiceId: payload.playServiceId
                    )
                }
            }).flatMapError({ (error) -> Result<Void, Error> in
                self.sendEvent(typeInfo: .playbackFailed(error: error))
                return .failure(error)
            })
            
            completionHandler(result)
        }
    }
}

// MARK: - Private (Event)

private extension AudioPlayerAgent {
    func sendEvent(typeInfo: Event.TypeInfo) {
        guard let media = currentMedia else {
            log.info("audioPlayerItem is nil")
            return
        }
        
        sendEvent(
            Event(
                token: media.payload.audioItem.stream.token,
                // This is a mandatory in Play kit.
                offsetInMilliseconds: (offset ?? 0) * 1000,
                playServiceId: media.payload.playServiceId,
                typeInfo: typeInfo
            ),
            context: contextInfoRequestContext(),
            dialogRequestId: TimeUUID().hexString,
            by: messageSender
        )
    }
}

// MARK: - Private(FocusManager)

private extension AudioPlayerAgent {
    func releaseFocus() {
        guard focusState != .nothing else { return }
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
                return self?.currentMedia?.player.offset ?? -1
            })
            .filter { $0 > 0 }
            .filter { $0 != lastOffset}
            .do(onNext: { [weak self] (offset) in
                log.debug(offset)
                if delayReportTime > 0, offset == delayReportTime {
                    self?.sendEvent(typeInfo: .progressReportDelayElapsed)
                }
                if intervalReportTime > 0, offset % intervalReportTime == 0 {
                    self?.sendEvent(typeInfo: .progressReportIntervalElapsed)
                }
                lastOffset = offset
            }).subscribe()
        intervalReporter?.disposed(by: disposeBag)
    }
    
    func stopProgressReport() {
        intervalReporter?.dispose()
    }
    
    func startPauseTimeout() {
        stopPauseTimeout()
        pauseTimeout = Completable.create { [weak self] event -> Disposable in
            if let self = self, let media = self.currentMedia {
                self.playSyncManager.releaseSyncImmediately(dialogRequestId: media.dialogRequestId, playServiceId: media.payload.playServiceId)
            }
            event(.completed)
            return Disposables.create()
        }
            .delaySubscription(NuguApp.shared.configuration.audioPlayerPauseTimeout, scheduler: audioPlayerScheduler)
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
        let mediaPlayer = self.mediaPlayerFactory.makeMediaPlayer(type: .media)
        mediaPlayer.delegate = self
        self.currentMedia = AudioPlayerAgentMedia(dialogRequestId: dialogRequestId, player: mediaPlayer, payload: payload)
        try mediaPlayer.setSource(
            url: payload.audioItem.stream.url,
            offset: payload.audioItem.stream.offset
        )
        mediaPlayer.isMuted = playerIsMuted
        playSyncManager.prepareSync(delegate: self, dialogRequestId: dialogRequestId, playServiceId: payload.playServiceId)
    }
}

// MARK: - MediaPlayerState + EventInfo

private extension MediaPlayerState {
    var eventTypeInfo: AudioPlayerAgent.Event.TypeInfo? {
        switch self {
        case .bufferRefilled, .bufferUnderrun:
            return nil
        case .start:
            return .playbackStarted
        case .stop:
            return .playbackStopped
        case .pause:
            return .playbackPaused
        case .resume:
            return .playbackResumed
        case .finish:
            return .playbackFinished
        case .error(let error):
            return .playbackFailed(error: error)
        }
    }
}
