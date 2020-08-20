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
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .textToSpeech, version: "1.2")
    private let playSyncProperty = PlaySyncProperty(layerType: .info, contextType: .sound)
    
    // TTSAgentProtocol
    public var directiveCancelPolicy: DirectiveCancelPolicy = .cancelNone
    public var offset: Int? {
        return currentPlayer?.offset.truncatedSeconds
    }
    
    public var duration: Int? {
        return currentPlayer?.duration.truncatedSeconds
    }
    
    public var volume: Float = 1.0 {
        didSet {
            currentPlayer?.volume = volume
        }
    }
    
    // Private
    private let playSyncManager: PlaySyncManageable
    private let contextManager: ContextManageable
    private let focusManager: FocusManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    private let ttsDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.tts_agent", qos: .userInitiated)
    
    private let delegates = DelegateSet<TTSAgentDelegate>()
    
    private var ttsState: TTSState = .idle {
        didSet {
            log.info("state changed from: \(oldValue) to: \(ttsState)")
            guard let media = currentMedia else {
                log.error("TTSMedia is nil")
                return
            }
            
            // `PlaySyncState` -> `TTSMedia` -> `TTSAgentDelegate`
            switch ttsState {
            case .playing:
                if let playServiceId = media.payload.playServiceId {
                    playSyncManager.startPlay(
                        property: playSyncProperty,
                        info: PlaySyncInfo(
                            playServiceId: playServiceId,
                            playStackServiceId: media.payload.playStackControl?.playServiceId,
                            dialogRequestId: media.dialogRequestId,
                            messageId: media.messageId,
                            duration: NuguTimeInterval(seconds: 7)
                        )
                    )
                }
            case .finished, .stopped:
                if media.payload.playServiceId != nil {
                    if media.cancelAssociation {
                        playSyncManager.stopPlay(dialogRequestId: media.dialogRequestId)
                    } else {
                        playSyncManager.endPlay(property: playSyncProperty)
                    }
                }
                currentPlayer = nil
            default:
                break
            }
            
            // Notify delegates only if the agent's status changes.
            if oldValue != ttsState {
                delegates.notify { delegate in
                    delegate.ttsAgentDidChange(state: ttsState, dialogRequestId: media.dialogRequestId)
                }
            }
        }
    }
    
    private let ttsResultSubject = PublishSubject<(dialogRequestId: String, result: TTSResult)>()
    
    // Current play Info
    private var currentMedia: TTSMedia?
    private var currentPlayer: MediaPlayable?

    private let disposeBag = DisposeBag()
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Speak", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), preFetch: prefetchPlay, directiveHandler: handlePlay, attachmentHandler: handleAttachment),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Stop", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleStop)
    ]
    
    public init(
        focusManager: FocusManageable,
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        self.focusManager = focusManager
        self.upstreamDataSender = upstreamDataSender
        self.playSyncManager = playSyncManager
        self.contextManager = contextManager
        self.directiveSequencer = directiveSequencer
        
        playSyncManager.add(delegate: self)
        contextManager.add(delegate: self)
        focusManager.add(channelDelegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
        currentPlayer?.stop()
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
    
    func requestTTS(
        text: String,
        playServiceId: String?,
        handler: ((_ ttsResult: TTSResult, _ dialogRequestId: String) -> Void)?
    ) -> String {
        let eventIdentifier = EventIdentifier()
        contextManager.getContexts(namespace: self.capabilityAgentProperty.name) { [weak self] contextPayload in
            guard let self = self else { return }
            
            self.upstreamDataSender.sendEvent(
                Event(
                    token: nil,
                    playServiceId: playServiceId,
                    typeInfo: .speechPlay(text: text)
                ).makeEventMessage(
                    property: self.capabilityAgentProperty,
                    eventIdentifier: eventIdentifier,
                    contextPayload: contextPayload
                )
            )
        }
        
        ttsResultSubject
            .filter { $0.dialogRequestId == eventIdentifier.dialogRequestId }
            .take(1)
            .subscribe(onNext: { (dialogRequestId, result) in
                handler?(result, dialogRequestId)
            })
            .disposed(by: self.disposeBag)
        return eventIdentifier.dialogRequestId
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
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            log.info("\(focusState) \(self.ttsState)")
            
            switch (focusState, self.ttsState) {
            case (.foreground, let ttsState) where [.idle, .stopped, .finished].contains(ttsState):
                self.currentPlayer?.play()
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
    public func contextInfoRequestContext(completion: (ContextInfo?) -> Void) {
        let payload: [String: AnyHashable] = [
            "ttsActivity": ttsState.value,
            "version": capabilityAgentProperty.version,
            "engine": "skt",
            "token": currentMedia?.payload.token
        ]
        completion(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
    }
}

// MARK: - MediaPlayerDelegate

extension TTSAgent: MediaPlayerDelegate {
    public func mediaPlayerDidChange(state: MediaPlayerState) {
        log.info("media state: \(state)")
        
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let media = self.currentMedia else { return }
            
            // `TTSResult` -> `TTSState` -> Event -> `FocusState`
            switch state {
            case .start:
                self.ttsState = .playing
                self.sendEvent(media: media, info: .speechStarted)
            case .resume, .bufferRefilled:
                self.ttsState = .playing
            case .finish:
                self.ttsState = .finished
                self.sendEvent(media: media, info: .speechFinished) { [weak self] state in
                    self?.ttsDispatchQueue.async { [weak self] in
                        guard let self = self else { return }
                        
                        switch state {
                        case .finished, .error:
                            if self.currentPlayer == nil {
                                self.releaseFocusIfNeeded()
                            }
                            self.ttsResultSubject.onNext((dialogRequestId: media.dialogRequestId, result: .finished))
                        default:
                            break
                        }
                    }
                }
            case .pause:
                self.stop(cancelAssociation: false)
            case .stop:
                self.ttsResultSubject.onNext(
                    (dialogRequestId: media.dialogRequestId, result: .stopped(cancelAssociation: media.cancelAssociation))
                )
                self.ttsState = .stopped
                self.sendEvent(media: media, info: .speechStopped)
                self.releaseFocusIfNeeded()
            case .bufferUnderrun:
                break
            case .error(let error):
                self.ttsResultSubject.onNext((dialogRequestId: media.dialogRequestId, result: .error(error)))
                self.ttsState = .stopped
                self.sendEvent(media: media, info: .speechStopped)
                self.releaseFocusIfNeeded()
            }
        }
    }
}

// MARK: - PlaySyncDelegate

extension TTSAgent: PlaySyncDelegate {
    public func playSyncDidRelease(property: PlaySyncProperty, messageId: String) {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard property == self.playSyncProperty, self.currentMedia?.messageId == messageId else { return }
            
            self.stop(cancelAssociation: true)
        }
    }
}

// MARK: - Private (Directive)

private extension TTSAgent {
    func prefetchPlay() -> PrefetchDirective {
        return { [weak self] directive in
            let payload = try JSONDecoder().decode(TTSMedia.Payload.self, from: directive.payload)
            guard case .attachment = payload.sourceType else {
                throw TTSError.notSupportedSourceType
            }
            
            self?.ttsDispatchQueue.sync { [weak self] in
                guard let self = self else { return }
                
                self.stopSilently()
                
                do {
                    let mediaPlayer = try OpusPlayer()
                    mediaPlayer.delegate = self
                    mediaPlayer.volume = self.volume

                    self.currentPlayer = mediaPlayer
                    self.currentMedia = TTSMedia(
                        payload: payload,
                        dialogRequestId: directive.header.dialogRequestId,
                        messageId: directive.header.messageId
                    )
                } catch {
                    // TODO: 실패시 예외처리 필요한지 확인
                    log.error("Opus player initiation error: \(error)")
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
            log.debug("")
            self.focusManager.requestFocus(channelDelegate: self)
            self.ttsDispatchQueue.async { [weak self] in
                guard let self = self else {
                    completion(.canceled)
                    return
                }
                guard let media = self.currentMedia, media.messageId == directive.header.messageId else {
                    self.releaseFocusIfNeeded()
                    completion(.canceled)
                    log.info("Message id does not match")
                    return
                }
                
                self.delegates.notify { delegate in
                    delegate.ttsAgentDidReceive(text: media.payload.text, dialogRequestId: media.dialogRequestId)
                }
                
                self.ttsResultSubject
                    .filter { $0.dialogRequestId == media.dialogRequestId }
                    .take(1)
                    .subscribe(onNext: { [weak self] (_, result) in
                        guard let self = self else {
                            completion(.canceled)
                            return
                        }
                        switch result {
                        case .finished:
                            completion(.finished)
                        case .stopped(let cancelAssociation):
                            if cancelAssociation {
                                completion(.stopped(directiveCancelPolicy: .cancelAll))
                            } else {
                                completion(.stopped(directiveCancelPolicy: self.directiveCancelPolicy))
                            }
                        case .error(let error):
                            completion(.failed("\(error)"))
                        }
                    })
                    .disposed(by: self.disposeBag)
            }
        }
    }
    
    func handleStop() -> HandleDirective {
        return { [weak self] _, completion in
            defer { completion(.finished) }
            
            guard let self = self, let media = self.currentMedia else { return }
            guard self.currentPlayer != nil else {
                // Release synchronized layer after playback finished.
                if media.payload.playServiceId != nil {
                    self.playSyncManager.stopPlay(dialogRequestId: media.dialogRequestId)
                }
                return
            }
            
            self.stop(cancelAssociation: true)
        }
    }
    
    func stop(cancelAssociation: Bool) {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self, let player = self.currentPlayer else { return }
            
            self.currentMedia?.cancelAssociation = cancelAssociation
            player.stop()
        }
    }
    
    /// Synchronously stop previously playing TTS
    func stopSilently() {
        guard let media = currentMedia, let player = currentPlayer else { return }

        currentMedia?.cancelAssociation = false
        // `TTSResult` -> `TTSState` -> Event
        player.delegate = nil
        player.stop()
        ttsResultSubject.onNext(
            (dialogRequestId: media.dialogRequestId, result: .stopped(cancelAssociation: media.cancelAssociation))
        )
        ttsState = .stopped
        sendEvent(media: media, info: .speechStopped)
    }
    
    func handleAttachment() -> HandleAttachment {
        #if DEBUG
        var totalAttachmentData = Data()
        #endif
        
        return { [weak self] attachment in
            #if DEBUG
            totalAttachmentData.append(attachment.content)
            #endif
            
            self?.ttsDispatchQueue.async { [weak self] in
                log.info("\(attachment)")
                guard let self = self else { return }
                guard let dataSource = self.currentPlayer as? MediaOpusStreamDataSource,
                    self.currentMedia?.dialogRequestId == attachment.header.dialogRequestId else {
                    log.warning("MediaOpusStreamDataSource not exist or dialogRequesetId not valid")
                    return
                }
                
                do {
                    try dataSource.appendData(attachment.content)
                    
                    if attachment.isEnd {
                        try dataSource.lastDataAppended()
                        
                        #if DEBUG
                        let attachmentFileName = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            .appendingPathComponent("attachment.data")
                        try totalAttachmentData.write(to: attachmentFileName)
                        log.debug("attachment to file :\(attachmentFileName)")
                        #endif
                    }
                } catch {
                    log.error(error)
                }
            }
        }
    }
}

// MARK: - Private (Event)

private extension TTSAgent {
    func sendEvent(
        media: TTSMedia,
        info: Event.TypeInfo,
        completion: ((StreamDataState) -> Void)? = nil
    ) {
        guard let playServiceId = media.payload.playServiceId else {
            log.debug("TTSMedia does not have playServiceId")
            completion?(.finished)
            return
        }
        
        let eventIdentifier = EventIdentifier()
        contextManager.getContexts(namespace: capabilityAgentProperty.name) { [weak self] contextPayload in
            guard let self = self else { return }
            
            self.upstreamDataSender.sendEvent(
                Event(
                    token: media.payload.token,
                    playServiceId: playServiceId,
                    typeInfo: info
                ).makeEventMessage(
                    property: self.capabilityAgentProperty,
                    eventIdentifier: eventIdentifier,
                    referrerDialogRequestId: media.dialogRequestId,
                    contextPayload: contextPayload
                ),
                completion: completion
            )
        }
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
