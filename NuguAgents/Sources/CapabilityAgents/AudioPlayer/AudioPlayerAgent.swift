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
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .audioPlayer, version: "1.4")
    private let playSyncProperty = PlaySyncProperty(layerType: .media, contextType: .sound)
    
    // AudioPlayerAgentProtocol
    public weak var displayDelegate: AudioPlayerDisplayDelegate? {
        didSet {
            audioPlayerDisplayManager.delegate = displayDelegate
        }
    }
    
    public var offset: Int? {
        latestPlayer?.offset.truncatedSeconds
    }
    
    public var duration: Int? {
        latestPlayer?.duration.truncatedSeconds
    }
    
    public var volume: Float = 1.0 {
        didSet {
            latestPlayer?.volume = volume
        }
    }
    
    public var isPlaying: Bool {
        return audioPlayerState == .playing
    }
    
    // Private
    private let playSyncManager: PlaySyncManageable
    private let contextManager: ContextManageable
    private let focusManager: FocusManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    private let audioPlayerPauseTimeout: DispatchTimeInterval
    private lazy var audioPlayerDisplayManager: AudioPlayerDisplayManageable = AudioPlayerDisplayManager(
        audioPlayerPauseTimeout: audioPlayerPauseTimeout,
        audioPlayerAgent: self,
        playSyncManager: playSyncManager
    )
    private let delegates = DelegateSet<AudioPlayerAgentDelegate>()
    
    private let audioPlayerDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.audioplayer_agent", qos: .userInitiated)
    private lazy var audioPlayerScheduler = SerialDispatchQueueScheduler(
        queue: audioPlayerDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.audioplayer_agent"
    )
    
    private var audioPlayerState: AudioPlayerState = .idle {
        didSet {
            if oldValue != audioPlayerState {
                log.info("AudioPlayerAgent state changed \(oldValue) -> \(audioPlayerState)")
            }
            
            guard let player = self.latestPlayer else {
                log.error("AudioPlayer is nil")
                return
            }
            
            // `PlaySyncState` -> `AudioPlayerAgentDelegate`
            switch audioPlayerState {
            case .playing:
                playSyncManager.cancelTimer(property: playSyncProperty)
            case .stopped, .finished:
                if player.cancelAssociation {
                    playSyncManager.stopPlay(dialogRequestId: player.dialogRequestId)
                } else {
                    playSyncManager.endPlay(property: playSyncProperty)
                }
            case .paused(let temporary):
                if temporary == false {
                    playSyncManager.startTimer(property: playSyncProperty, duration: audioPlayerPauseTimeout)
                }
            default:
                break
            }
            
            // Notify delegates only if the agent's status changes.
            if oldValue != audioPlayerState {
                delegates.notify { delegate in
                    delegate.audioPlayerAgentDidChange(state: audioPlayerState, dialogRequestId: player.dialogRequestId)
                }
            }
        }
    }
    
    // Players
    private var currentPlayer: AudioPlayer?
    private var prefetchPlayer: AudioPlayer?
    private var latestPlayer: AudioPlayer? {
        prefetchPlayer ?? currentPlayer
    }
    
    private var disposeBag = DisposeBag()
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Play", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), preFetch: prefetchPlay, directiveHandler: handlePlay, attachmentHandler: handleAttachment),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Stop", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleStop),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Pause", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handlePause),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "RequestPlayCommand", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleRequestPlayCommand),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "RequestResumeCommand", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleRequestResumeCommand),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "RequestNextCommand", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleRequestNextCommand),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "RequestPreviousCommand", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleRequestPreviousCommand),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "RequestPauseCommand", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleRequestPauseCommand),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "RequestStopCommand", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleRequestStopCommand),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "UpdateMetadata", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleUpdateMetadata),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ShowLyrics", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleShowLyrics),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "HideLyrics", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleHideLyrics),
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
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        self.audioPlayerPauseTimeout = audioPlayerPauseTimeout

        playSyncManager.add(delegate: self)
        contextManager.add(delegate: self)
        focusManager.add(channelDelegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }

    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        currentPlayer?.stop()
        prefetchPlayer?.stop()
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
            guard let player = self.latestPlayer else {
                log.debug("Skip, MediaPlayer not exist.")
                return
            }
            player.pauseReason = .nothing
            self.currentPlayer = player
            self.focusManager.requestFocus(channelDelegate: self)
        }
    }
    
    func stop() {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let player = self?.latestPlayer else { return }
            
            self?.stop(player: player, cancelAssociation: true)
        }
    }
    
    @discardableResult func next(completion: ((StreamDataState) -> Void)?) -> String {
        return sendFullContextEvent(playEvent(typeInfo: .nextCommandIssued), completion: completion).dialogRequestId
    }
    
    @discardableResult func prev(completion: ((StreamDataState) -> Void)?) -> String {
        return sendFullContextEvent(playEvent(typeInfo: .previousCommandIssued), completion: completion).dialogRequestId
    }
    
    func pause() {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self,
                let player = self.latestPlayer else {
                    return
            }
            switch self.audioPlayerState {
            case .playing:
                player.pause(reason: .user)
            case .paused:
                player.pauseReason = .user
                self.audioPlayerState = .paused(temporary: false)
                self.sendCompactContextEvent(self.playEvent(player: player, typeInfo: .playbackPaused))
            default:
                break
            }
        }
    }
    
    func requestFavoriteCommand(current: Bool) {
        sendFullContextEvent(settingsEvent(typeInfo: .favoriteCommandIssued(current: current)))
    }

    func requestRepeatCommand(currentMode: AudioPlayerDisplayRepeat) {
        sendFullContextEvent(settingsEvent(typeInfo: .repeatCommandIssued(currentMode: currentMode)))
    }
    
    func requestShuffleCommand(current: Bool) {
        sendFullContextEvent(settingsEvent(typeInfo: .shuffleCommandIssued(current: current)))
    }
    
    func seek(to offset: Int) {
        audioPlayerDispatchQueue.async { [weak self] in
            self?.latestPlayer?.seek(to: NuguTimeInterval(seconds: offset))
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
        audioPlayerDisplayManager.notifyUserInteraction()
    }
}

// MARK: - FocusChannelDelegate

extension AudioPlayerAgent: FocusChannelDelegate {
    public func focusChannelPriority() -> FocusChannelPriority {
        return .media
    }
    
    public func focusChannelDidChange(focusState: FocusState) {
        audioPlayerDispatchQueue.sync { [weak self] in
            guard let self = self else { return }
            
            log.info("\(focusState) \(self.audioPlayerState)")
            switch (focusState, self.audioPlayerState) {
            // Directive 에 의한 Pause 인경우 재생하지 않음.
            case (.foreground, .paused):
                if self.currentPlayer?.pauseReason != .user {
                    self.currentPlayer?.resume()
                }
            case (.foreground, _):
                if let player = self.currentPlayer, player.internalPlayer != nil {
                    player.play()
                } else {
                    log.error("currentPlayer is nil")
                    releaseFocusIfNeeded()
                }
            case (.background, .playing):
                self.currentPlayer?.pause(reason: .focus)
            case (.background, _):
                if self.currentPlayer?.pauseReason == .nothing {
                    self.currentPlayer?.pause(reason: .focus)
                }
            case (.nothing, _):
                if let player = self.currentPlayer {
                    self.stop(player: player, cancelAssociation: false)
                }
            }
        }
    }
}

// MARK: - MediaPlayerDelegate

extension AudioPlayerAgent: MediaPlayerDelegate {
    public func mediaPlayer(_ mediaPlayer: MediaPlayable, didChange state: MediaPlayerState) {
        guard let player = mediaPlayer as? AudioPlayer else { return }
        
        audioPlayerDispatchQueue.async { [weak self] in
            log.info("\(state)")
            guard let self = self else { return }
            
            var audioPlayerState: AudioPlayerState?
            var eventTypeInfo: PlayEvent.TypeInfo?
            
            switch state {
            case .start:
                audioPlayerState = .playing
                eventTypeInfo = .playbackStarted
            case .resume:
                audioPlayerState = .playing
                if player.pauseReason != .focus {
                    eventTypeInfo = .playbackResumed
                }
            case .finish:
                audioPlayerState = .finished
                eventTypeInfo = .playbackFinished
            case .pause:
                if player.pauseReason != .focus {
                    audioPlayerState = .paused(temporary: false)
                } else {
                    audioPlayerState = .paused(temporary: true)
                }
                if player.pauseReason != .focus {
                    eventTypeInfo = .playbackPaused
                }
            case .stop:
                audioPlayerState = .stopped
                eventTypeInfo = .playbackStopped(reason: player.stopReason.rawValue)
            case .error(let error):
                audioPlayerState = .stopped
                eventTypeInfo = .playbackFailed(error: error)
            case .bufferUnderrun, .bufferRefilled:
                break
            }
            
            // `AudioPlayerState` -> `FocusState` -> Event
            if let audioPlayerState = audioPlayerState, self.latestPlayer === player {
                self.audioPlayerState = audioPlayerState
                switch audioPlayerState {
                case .stopped, .finished:
                    self.releaseFocusIfNeeded()
                default:
                    break
                }
            }
            if let eventTypeInfo = eventTypeInfo {
                self.sendCompactContextEvent(self.playEvent(player: player, typeInfo: eventTypeInfo))
            }
        }
    }
}

// MARK: - ContextInfoDelegate

extension AudioPlayerAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: @escaping (ContextInfo?) -> Void) {
        var payload: [String: AnyHashable?] = [
            "version": capabilityAgentProperty.version,
            "playServiceId": latestPlayer?.payload.playServiceId,
            "playerActivity": audioPlayerState.playerActivity,
            // This is a mandatory in Play kit.
            "offsetInMilliseconds": latestPlayer?.offset.truncatedMilliSeconds,
            "token": latestPlayer?.payload.audioItem.stream.token,
            "lyricsVisible": false
        ]
        payload["durationInMilliseconds"] = latestPlayer?.duration.truncatedMilliSeconds
        
        if let playServiceId = latestPlayer?.payload.playServiceId {
            let semaphore = DispatchSemaphore(value: 0)
            audioPlayerDisplayManager.isLyricsVisible(playServiceId: playServiceId) { result in
                payload["lyricsVisible"] = result
                semaphore.signal()
            }
            if semaphore.wait(timeout: .now() + .seconds(5)) == .timedOut {
                log.error("`isLyricsVisible` completion block does not called")
            }
        }
        
        completion(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
    }
}

// MARK: - PlaySyncDelegate

extension AudioPlayerAgent: PlaySyncDelegate {
    public func playSyncDidRelease(property: PlaySyncProperty, messageId: String) {
        audioPlayerDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard property == self.playSyncProperty,
                  let player = self.latestPlayer, player.messageId == messageId else { return }
            
            self.stop(player: player, cancelAssociation: true)
        }
    }
}

// MARK: - AudioPlayerProgressDelegate

extension AudioPlayerAgent: AudioPlayerProgressDelegate {
    func audioPlayer(_ player: AudioPlayer, didReportDelay progress: TimeIntervallic) {
        log.debug(player.offset.truncatedMilliSeconds)
        sendCompactContextEvent(playEvent(player: player, typeInfo: .progressReportDelayElapsed))
    }
    
    func audioPlayer(_ player: AudioPlayer, didReportInterval progress: TimeIntervallic) {
        log.debug(player.offset.truncatedMilliSeconds)
        sendCompactContextEvent(playEvent(player: player, typeInfo: .progressReportIntervalElapsed))
    }
}

// MARK: - Private (Directive)

private extension AudioPlayerAgent {
    func prefetchPlay() -> PrefetchDirective {
        return { [weak self] directive in
            self?.audioPlayerDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                if self.audioPlayerState != .idle {
                    self.audioPlayerState = .stopped
                }
                self.prefetchPlayer?.stop(reason: .playAnother)
                do {
                    self.prefetchPlayer = try AudioPlayer(directive: directive)
                    self.prefetchPlayer?.delegate = self
                    self.prefetchPlayer?.progressDelegate = self
                    self.prefetchPlayer?.volume = self.volume
                } catch {
                    log.error(error)
                }
                
                if let currentPlayer = self.currentPlayer {
                    self.prefetchPlayer?.tryToResume(player: currentPlayer)
                }
                self.currentPlayer?.stop(reason: .playAnother)
                
                if let player = self.prefetchPlayer {
                    self.playSyncManager.startPlay(
                        property: self.playSyncProperty,
                        info: PlaySyncInfo(
                            playStackServiceId: player.payload.playStackControl?.playServiceId,
                            dialogRequestId: player.dialogRequestId,
                            messageId: player.messageId,
                            duration: NuguTimeInterval(seconds: 7)
                        )
                    )
                    
                    self.audioPlayerDisplayManager.display(
                        payload: player.payload,
                        messageId: directive.header.messageId,
                        dialogRequestId: directive.header.dialogRequestId
                    )
                }
            }
        }
    }
    
   func handlePlay() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
            
            self.audioPlayerDispatchQueue.async { [weak self] in
                defer { completion(.finished) }
                
                guard let self = self else { return }
                guard let player = self.prefetchPlayer, player.messageId == directive.header.messageId else {
                    log.info("Message id does not match")
                    return
                }
                guard player.internalPlayer != nil else {
                    log.info("Internal player is nil")
                    return
                }
                
                self.currentPlayer = player
                self.prefetchPlayer = nil
                self.focusManager.requestFocus(channelDelegate: self)
            }
        }
    }
    
   func handleStop() -> HandleDirective {
        return { [weak self] _, completion in
            defer { completion(.finished) }
            
            guard let self = self, let player = self.latestPlayer else { return }
            guard player.internalPlayer != nil else {
                // Release synchronized layer after playback finished.
                self.playSyncManager.stopPlay(dialogRequestId: player.dialogRequestId)
                return
            }
            
            self.stop(player: player, cancelAssociation: true)
        }
    }
    
   func handlePause() -> HandleDirective {
        return { [weak self] _, completion in
            defer { completion(.finished) }
            
            self?.pause()
        }
    }
    
    func handleRequestPlayCommand() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payloadDictionary = directive.payloadDictionary else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            guard let self = self else { return }

            self.sendFullContextEvent(
                self.requestPlayEvent(
                    typeInfo: .requestPlayCommandIssued(payload: payloadDictionary),
                    referrerDialogRequestId: directive.header.dialogRequestId
                )
            )
        }
    }
    
    func handleRequestResumeCommand() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion(.finished) }
            
            self?.sendRequestCommandEvent(typeInfo: .requestResumeCommandIssued, directive: directive)
        }
    }
    
    func handleRequestNextCommand() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion(.finished) }
            
            self?.sendRequestCommandEvent(typeInfo: .requestNextCommandIssued, directive: directive)
        }
    }
    
    func handleRequestPreviousCommand() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion(.finished) }
            
            self?.sendRequestCommandEvent(typeInfo: .requestPreviousCommandIssued, directive: directive)
        }
    }
    
    func handleRequestPauseCommand() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion(.finished) }
            
            self?.sendRequestCommandEvent(typeInfo: .requestPauseCommandIssued, directive: directive)
        }
    }
    
    func handleRequestStopCommand() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion(.finished) }
            
            self?.sendRequestCommandEvent(typeInfo: .requestStopCommandIssued, directive: directive)
        }
    }
    
    func handleUpdateMetadata() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let playServiceId = directive.payloadDictionary?["playServiceId"] as? String else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            
            self?.audioPlayerDisplayManager.updateMetadata(payload: directive.payload, playServiceId: playServiceId)
        }
    }
    
    func handleShowLyrics() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let playServiceId = directive.payloadDictionary?["playServiceId"] as? String else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            
            self?.audioPlayerDisplayManager.showLyrics(playServiceId: playServiceId) { [weak self] isSuccess in
                guard let self = self else { return }
                
                let typeInfo: LyricsEvent.TypeInfo = isSuccess ? .showLyricsSucceeded : .showLyricsFailed
                self.sendFullContextEvent(
                    self.lyricsEvent(
                        typeInfo: typeInfo,
                        playServiceId: playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
                )
            }
        }
    }
    
    func handleHideLyrics() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let playServiceId = directive.payloadDictionary?["playServiceId"] as? String else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            
            self?.audioPlayerDisplayManager.hideLyrics(playServiceId: playServiceId) { [weak self] isSuccess in
                guard let self = self else { return }
                
                let typeInfo: LyricsEvent.TypeInfo = isSuccess ? .hideLyricsSucceeded : .hideLyricsFailed
                self.sendFullContextEvent(
                    self.lyricsEvent(
                        typeInfo: typeInfo,
                        playServiceId: playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
                )
            }
        }
    }
    
    func handleControlLyricsPage() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payload = try? JSONDecoder().decode(AudioPlayerDisplayControlPayload.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }
            
            self?.audioPlayerDisplayManager.controlLyricsPage(payload: payload) { [weak self] isSuccess in
                guard let self = self else { return }
                
                let typeInfo: LyricsEvent.TypeInfo = isSuccess ? .controlLyricsPageSucceeded(direction: payload.direction) : .controlLyricsPageFailed(direction: payload.direction)
                self.sendFullContextEvent(
                    self.lyricsEvent(
                        typeInfo: typeInfo,
                        playServiceId: payload.playServiceId,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
                )
            }
        }
    }
    
    func handleAttachment() -> HandleAttachment {
        return { [weak self] attachment in
            self?.audioPlayerDispatchQueue.async { [weak self] in
                log.info("\(attachment.header.messageId)")
                guard let self = self else { return }
                guard self.prefetchPlayer?.handleAttachment(attachment) == true ||
                        self.currentPlayer?.handleAttachment(attachment) == true else {
                    log.warning("MediaOpusStreamDataSource not exist or dialogRequesetId not valid")
                    return
                }
            }
        }
    }
    
    func stop(player: AudioPlayer, cancelAssociation: Bool) {
        player.cancelAssociation = cancelAssociation
        player.stop()
    }
}

// MARK: - Private (Send event)

private extension AudioPlayerAgent {
    @discardableResult func sendCompactContextEvent(
        _ event: Single<ResponseEvent>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(namespace: self.capabilityAgentProperty.name),
            property: self.capabilityAgentProperty, completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
    
    @discardableResult func sendFullContextEvent(
        _ event: Single<ResponseEvent>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(),
            property: self.capabilityAgentProperty, completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
    
    func sendRequestCommandEvent(typeInfo: PlayEvent.TypeInfo, directive: Downstream.Directive) {
        let event = self.requestCommandEvent(
            typeInfo: typeInfo,
            referrerDialogRequestId: directive.header.dialogRequestId
        ).do(onError: { _ in
            let failedEvent = self.requestPlayEvent(
                typeInfo: .requestCommandFailed(state: self.audioPlayerState, directiveType: directive.header.type),
                referrerDialogRequestId: directive.header.dialogRequestId
            )
            self.sendCompactContextEvent(failedEvent)
        })
        self.sendFullContextEvent(event)
    }
}


// MARK: - Private (ResponseEvent)

private extension AudioPlayerAgent {
    func playEvent(player: AudioPlayer, typeInfo: PlayEvent.TypeInfo) -> Single<ResponseEvent> {
        let playEvent = PlayEvent(
            token: player.payload.audioItem.stream.token,
            // This is a mandatory in Play kit.
            offsetInMilliseconds: player.offset.truncatedMilliSeconds,
            playServiceId: player.payload.playServiceId,
            typeInfo: typeInfo
        )
        return Single.just(ResponseEvent(event: playEvent, referrerDialogRequestId: player.dialogRequestId))
    }
    
    func playEvent(typeInfo: PlayEvent.TypeInfo) -> Single<ResponseEvent> {
        return Single<AudioPlayer>.create { [weak self] (observer) -> Disposable in
            guard let self = self, let player = self.latestPlayer else {
                observer(.error(AudioPlayerAgentError.playerNotExist))
                return Disposables.create()
            }
            
            observer(.success(player))
            return Disposables.create()
        }.subscribeOn(audioPlayerScheduler)
        .flatMap { [weak self] in
            guard let self = self else {
                return Single.error(RxError.noElements)
            }
            
            return self.playEvent(player: $0, typeInfo: typeInfo)
        }
    }
    
    func requestPlayEvent(typeInfo: RequestPlayEvent.TypeInfo, referrerDialogRequestId: String) -> Single<ResponseEvent> {
        let requestPlayEvent = RequestPlayEvent(typeInfo: typeInfo)
        return Single.just(ResponseEvent(event: requestPlayEvent, referrerDialogRequestId: referrerDialogRequestId))
    }
    
    func requestCommandEvent(typeInfo: PlayEvent.TypeInfo, referrerDialogRequestId: String) -> Single<ResponseEvent> {
        return Single.create { [weak self] (observer) -> Disposable in
            guard let self = self, let player = self.latestPlayer else {
                observer(.error(AudioPlayerAgentError.playerNotExist))
                return Disposables.create()
            }
            
            let playEvent = PlayEvent(
                token: player.payload.audioItem.stream.token,
                // This is a mandatory in Play kit.
                offsetInMilliseconds: player.offset.truncatedMilliSeconds,
                playServiceId: player.payload.playServiceId,
                typeInfo: typeInfo
            )
            let event = ResponseEvent(event: playEvent, referrerDialogRequestId: referrerDialogRequestId)
            observer(.success(event))
            return Disposables.create()
        }.subscribeOn(audioPlayerScheduler)
    }

    func settingsEvent(typeInfo: SettingsEvent.TypeInfo) -> Single<ResponseEvent> {
        return Single.create { [weak self] (observer) -> Disposable in
            guard let self = self, let player = self.latestPlayer else {
                observer(.error(AudioPlayerAgentError.playerNotExist))
                return Disposables.create()
            }
            
            let settingEvent = SettingsEvent(
                playServiceId: player.payload.playServiceId,
                typeInfo: typeInfo
            )
            let event = ResponseEvent(event: settingEvent, referrerDialogRequestId: player.dialogRequestId)
            observer(.success(event))
            return Disposables.create()
        }.subscribeOn(audioPlayerScheduler)
    }
    
    func lyricsEvent(
        typeInfo: LyricsEvent.TypeInfo,
        playServiceId: String,
        referrerDialogRequestId: String
    ) -> Single<ResponseEvent>{
        let lyricsEvent = LyricsEvent(
            playServiceId: playServiceId,
            typeInfo: typeInfo
        )
        return Single.just(ResponseEvent(event: lyricsEvent, referrerDialogRequestId: referrerDialogRequestId))
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
