//
//  TTSAgent.swift
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

public final class TTSAgent: TTSAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .textToSpeech, version: "1.0")
    
    // Private
    private let playSyncManager: PlaySyncManageable
    private let focusManager: FocusManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    private let ttsDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.tts_agent", qos: .userInitiated)
    
    private let delegates = DelegateSet<TTSAgentDelegate>()
    
    private var ttsState: TTSState = .idle {
        didSet {
            log.info("\(oldValue) \(ttsState)")
            guard let media = currentMedia else {
                log.error("TTSMedia is nil")
                return
            }
            
            // `PlaySyncState` -> `TTSMedia` -> `TTSAgentDelegate`
            switch ttsState {
            case .playing:
                playSyncManager.startSync(
                    delegate: self,
                    dialogRequestId: media.dialogRequestId,
                    playServiceId: media.payload.playStackControl?.playServiceId
                )
            case .finished, .stopped:
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
            default:
                break
            }
            delegates.notify { delegate in
                delegate.ttsAgentDidChange(state: ttsState, dialogRequestId: media.dialogRequestId)
            }
        }
    }
    
    private let ttsResultSubject = PublishSubject<(dialogRequestId: String, result: TTSResult)>()
    
    // Current play Info
    private var currentMedia: TTSMedia?
    
    private var playerIsMuted: Bool = false {
        didSet {
            currentMedia?.player.isMuted = playerIsMuted
        }
    }
    
    private let disposeBag = DisposeBag()
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Speak", medium: .audio, isBlocking: true, preFetch: prefetchPlay, directiveHandler: handlePlay, attachmentHandler: handleAttachment),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Stop", medium: .none, isBlocking: false, directiveHandler: handleStop)
    ]
    
    public init(
        focusManager: FocusManageable,
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        log.info("")
        
        self.focusManager = focusManager
        self.upstreamDataSender = upstreamDataSender
        self.playSyncManager = playSyncManager
        self.directiveSequencer = directiveSequencer
        
        contextManager.add(provideContextDelegate: self)
        focusManager.add(channelDelegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        
        ttsResultSubject.subscribe(onNext: { [weak self] (_, result) in
            // Send error
            switch result {
            case .error(let error):
                self?.upstreamDataSender.sendCrashReport(error: error)
            default: break
            }
        }).disposed(by: disposeBag)
    }
    
    deinit {
        log.info("")
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - TTSAgentProtocol

public extension TTSAgent {
    func add(delegate: TTSAgentDelegate) {
        delegates.add(delegate)
    }
    
    func remove(delegate: TTSAgentDelegate) {
        delegates.remove(delegate)
    }
    
    func requestTTS(text: String, playServiceId: String?, handler: ((TTSResult) -> Void)?) {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            let dialogRequestId = TimeUUID().hexString
            self.upstreamDataSender.send(
                upstreamEventMessage: Event(
                    token: nil,
                    playServiceId: playServiceId,
                    typeInfo: .speechPlay(text: text)
                ).makeEventMessage(agent: self, dialogRequestId: dialogRequestId)
            )
            
            self.ttsResultSubject
                .filter { $0.dialogRequestId == dialogRequestId }
                .take(1)
                .do(onNext: { (_, result) in
                    handler?(result)
                })
                .subscribe().disposed(by: self.disposeBag)
        }
    }
    
    func stopTTS(cancelAssociation: Bool) {
        stop(cancelAssociation: cancelAssociation)
    }
}

// MARK: - FocusChannelDelegate

extension TTSAgent: FocusChannelDelegate {
    public func focusChannelPriority() -> FocusChannelPriority {
        return .information
    }
    
    public func focusChannelDidChange(focusState: FocusState) {
        log.info("\(focusState) \(ttsState)")
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch (focusState, self.ttsState) {
            case (.foreground, let ttsState) where [.idle, .stopped, .finished].contains(ttsState):
                self.currentMedia?.player.play()
            // Foreground. playing 무시
            case (.foreground, _):
                break
            case (.background, .playing):
                self.stop(cancelAssociation: false)
            // background. idle, stopped, finished 무시
            case (.background, _):
                break
            case (.nothing, .playing):
                self.stop(cancelAssociation: false)
            // none. idle/stopped/finished 무시
            case (.nothing, _):
                break
            }
        }
    }
}

// MARK: - ContextInfoDelegate

extension TTSAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completionHandler: (ContextInfo?) -> Void) {
        let payload: [String: Any] = [
            "ttsActivity": ttsState.value,
            "version": capabilityAgentProperty.version,
            "engine": "skt"
        ]
        completionHandler(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload))
    }
}

// MARK: - MediaPlayerDelegate

extension TTSAgent: MediaPlayerDelegate {
    public func mediaPlayerDidChange(state: MediaPlayerState) {
        log.info(state)
        
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let media = self.currentMedia else { return }
            
            // Event -> `TTSResult` -> `TTSState` -> `FocusState`
            switch state {
            case .start:
                self.sendEvent(media: media, info: .speechStarted)
                self.ttsState = .playing
            case .resume, .bufferRefilled:
                self.ttsState = .playing
            case .finish:
                self.ttsResultSubject.onNext((dialogRequestId: media.dialogRequestId, result: .finished))
                self.ttsState = .finished
                
                // Release focus after receiving directive
                self.sendEvent(media: media, info: .speechFinished) { [weak self] _ in
                    self?.releaseFocusIfNeeded()
                }
            case .pause:
                self.stop(cancelAssociation: false)
            case .stop:
                self.sendEvent(media: media, info: .speechStopped)
                self.ttsResultSubject.onNext(
                    (dialogRequestId: media.dialogRequestId, result: .stopped(cancelAssociation: media.cancelAssociation))
                )
                self.ttsState = .stopped
                self.releaseFocusIfNeeded()
            case .bufferUnderrun:
                break
            case .error(let error):
                self.sendEvent(media: media, info: .speechStopped)
                self.ttsResultSubject.onNext((dialogRequestId: media.dialogRequestId, result: .error(error)))
                self.ttsState = .stopped
                self.releaseFocusIfNeeded()
            }
        }
    }
}

// MARK: - PlaySyncDelegate

extension TTSAgent: PlaySyncDelegate {
    public func playSyncIsDisplay() -> Bool {
        return false
    }
    
    public func playSyncDuration() -> PlaySyncDuration {
        return .short
    }
    
    public func playSyncDidChange(state: PlaySyncState, dialogRequestId: String) {
        log.info("\(state)")
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let media = self.currentMedia, media.dialogRequestId == dialogRequestId else { return }
            
            if [.releasing, .released].contains(state) {
                self.stop(cancelAssociation: false)
            }
        }
    }
}

// MARK: - SpeakerVolumeDelegate

extension TTSAgent: SpeakerVolumeDelegate {
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

private extension TTSAgent {
    func prefetchPlay() -> HandleDirective {
        return { [weak self] directive, completionHandler in
            self?.ttsDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                completionHandler(
                    Result<Void, Error>(catching: {
                        guard let data = directive.payload.data(using: .utf8) else {
                            throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
                        }
                        
                        let payload = try JSONDecoder().decode(TTSMedia.Payload.self, from: data)
                        guard case .attachment = payload.sourceType else {
                            throw HandleDirectiveError.handleDirectiveError(message: "Not supported sourceType")
                        }
                        
                        self.stopSilently()
                        
                        let mediaPlayer = OpusPlayer()
                        mediaPlayer.delegate = self
                        mediaPlayer.isMuted = self.playerIsMuted
                        
                        self.currentMedia = TTSMedia(
                            player: mediaPlayer,
                            payload: payload,
                            dialogRequestId: directive.header.dialogRequestId
                        )
                        
                        self.playSyncManager.prepareSync(
                            delegate: self,
                            dialogRequestId: directive.header.dialogRequestId,
                            playServiceId: payload.playStackControl?.playServiceId
                        )
                    })
                )
            }
        }
    }
    
    func handlePlay() -> HandleDirective {
        return { [weak self] directive, completionHandler in
            self?.ttsDispatchQueue.async { [weak self] in
                guard let self = self else {
                    completionHandler(.success(()))
                    return
                }
                guard let media = self.currentMedia, media.dialogRequestId == directive.header.dialogRequestId else {
                    log.warning("TextToSpeechItem not exist or dialogRequesetId not valid")
                    completionHandler(.success(()))
                    return
                }
                
                self.delegates.notify { delegate in
                    delegate.ttsAgentDidReceive(text: media.payload.text, dialogRequestId: media.dialogRequestId)
                }
                
                self.ttsResultSubject
                    .filter { $0.dialogRequestId == media.dialogRequestId }
                    .take(1)
                    .do(onNext: { (_, _) in
                        completionHandler(.success(()))
                    })
                    .subscribe().disposed(by: self.disposeBag)
                
                self.focusManager.requestFocus(channelDelegate: self)
            }
        }
    }
    
    func handleStop() -> HandleDirective {
        return { [weak self] _, completionHandler in
            guard let self = self else { return }
            completionHandler(self.stop(cancelAssociation: true))
        }

    }
    
    @discardableResult func stop(cancelAssociation: Bool) -> Result<Void, Error> {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self, let media = self.currentMedia else { return }
            
            self.currentMedia?.cancelAssociation = cancelAssociation
            media.player.stop()
        }
        return .success(())
    }
    
    /// Stop previously playing TTS
    func stopSilently() {
        guard let media = currentMedia else { return }
        // Event -> `TTSResult` -> `TTSState`
        media.player.delegate = nil
        media.player.stop()
        sendEvent(media: media, info: .speechStopped)
        ttsResultSubject.onNext(
            (dialogRequestId: media.dialogRequestId, result: .stopped(cancelAssociation: media.cancelAssociation))
        )
        ttsState = .stopped
    }
    
    func handleAttachment() -> HandleAttachment {
        return { [weak self] attachment in
            log.info("\(attachment.header.messageId)")
            self?.ttsDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard let media = self.currentMedia, media.dialogRequestId == attachment.header.dialogRequestId else {
                    log.warning("TextToSpeechItem not exist or dialogRequesetId not valid")
                    return
                }
                
                let player = media.player as? MediaOpusStreamDataSource
                do {
                    try player?.appendData(attachment.content)
                    
                    if attachment.isEnd {
                        try player?.lastDataAppended()
                    }
                } catch {
                    self.upstreamDataSender.sendCrashReport(error: error)
                    log.error(error)
                }
            }
        }
    }
}

// MARK: - Private (Event)

private extension TTSAgent {
    func sendEvent(media: TTSMedia, info: Event.TypeInfo, resultHandler: ((Result<Downstream.Directive, Error>) -> Void)? = nil) {
        guard let playServiceId = media.payload.playServiceId else {
            log.debug("TTSMedia does not have playServiceId")
            
            let error = NSError(domain: "com.sktelecom.romaine.tts_agent", code: 1000, userInfo: nil)
            resultHandler?(.failure(error))
            return
        }
        
        self.upstreamDataSender.send(
            upstreamEventMessage: Event(
                token: media.payload.token,
                playServiceId: playServiceId,
                typeInfo: info
            ).makeEventMessage(agent: self),
            resultHandler: resultHandler
        )
    }
}

// MARK: - Private(FocusManager)

private extension TTSAgent {
    func releaseFocusIfNeeded() {
        guard [.idle, .stopped, .finished].contains(ttsState) else {
            log.info("Not permitted in current state, \(ttsState)")
            return
        }
        focusManager.releaseFocus(channelDelegate: self)
    }
}
