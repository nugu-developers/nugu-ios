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
import NuguUtils

import RxSwift

public final class TTSAgent: TTSAgentProtocol {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .textToSpeech, version: "1.3")
    private let playSyncProperty = PlaySyncProperty(layerType: .info, contextType: .sound)
    
    // TTSAgentProtocol
    public var directiveCancelPolicy: DirectiveCancelPolicy = .cancelNone
    public var offset: Int? {
        ttsDispatchQueue.sync {
            latestPlayer?.offset.truncatedSeconds
        }
    }
    
    public var duration: Int? {
        ttsDispatchQueue.sync {
            latestPlayer?.duration.truncatedSeconds
        }
    }
    
    public var volume: Float = 1.0 {
        didSet {
            ttsDispatchQueue.sync {
                latestPlayer?.volume = volume
            }
        }
    }
    
    // Private
    private let playSyncManager: PlaySyncManageable
    private let contextManager: ContextManageable
    private let focusManager: FocusManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    
    private let ttsDelegateDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.tts_agent_delegate")
    private let ttsDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.tts_agent", qos: .userInitiated)
    
    private let delegates = DelegateSet<TTSAgentDelegate>()
    
    private var ttsState: TTSState = .idle {
        didSet {
            log.info("state changed from: \(oldValue) to: \(ttsState)")
            guard let player = latestPlayer else {
                log.error("TTSPlayer is nil")
                return
            }
            
            // `PlaySyncState` -> `TTSAgentDelegate`
            switch ttsState {
            case .playing:
                if player.payload.playServiceId != nil {
                    playSyncManager.startPlay(
                        property: playSyncProperty,
                        info: PlaySyncInfo(
                            playStackServiceId: player.payload.playStackControl?.playServiceId,
                            dialogRequestId: player.header.dialogRequestId,
                            messageId: player.header.messageId,
                            duration: NuguTimeInterval(seconds: 7)
                        )
                    )
                }
            case .finished, .stopped:
                if player.payload.playServiceId != nil {
                    if player.cancelAssociation {
                        playSyncManager.stopPlay(dialogRequestId: player.header.dialogRequestId)
                    } else {
                        playSyncManager.endPlay(property: playSyncProperty)
                    }
                }
            default:
                break
            }
            
            // Notify delegates only if the agent's status changes.
            if oldValue != ttsState {
                let state = ttsState
                delegates.notify(queue: ttsDelegateDispatchQueue) { delegate in
                    delegate.ttsAgentDidChange(state: state, header: player.header)
                }
            }
        }
    }
    
    private let ttsResultSubject = PublishSubject<(dialogRequestId: String, result: TTSResult)>()
    
    // Players
    private var currentPlayer: TTSPlayer? {
        didSet {
            currentPlayer?.volume = volume
            prefetchPlayer = nil
        }
    }
    private var prefetchPlayer: TTSPlayer? {
        didSet {
            prefetchPlayer?.delegate = self
        }
    }
    private var latestPlayer: TTSPlayer? {
        prefetchPlayer ?? currentPlayer
    }

    private let disposeBag = DisposeBag()
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(
            namespace: capabilityAgentProperty.name,
            name: "Speak",
            blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true),
            preFetch: prefetchPlay,
            cancelDirective: cancelPlay,
            directiveHandler: handlePlay,
            attachmentHandler: handleAttachment
        ),
        DirectiveHandleInfo(
            namespace: capabilityAgentProperty.name,
            name: "Stop",
            blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false),
            directiveHandler: handleStop
        )
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
        prefetchPlayer?.stop()
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
        let eventIdentifier = sendCompactContextEvent(Event(
            typeInfo: .speechPlay(text: text),
            token: nil,
            playServiceId: playServiceId,
            referrerDialogRequestId: nil
        ).rx)
        
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
        ttsDispatchQueue.async { [weak self] in
            guard let player = self?.latestPlayer else { return }
            
            self?.stop(player: player, cancelAssociation: cancelAssociation)
        }
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
                if let player = self.currentPlayer, player.internalPlayer != nil {
                    player.play()
                } else {
                    log.error("currentPlayer is nil")
                    self.releaseFocusIfNeeded()
                }
            // Ignore (foreground, playing)
            case (.foreground, _):
                break
            case (.background, _), (.nothing, _):
                if let player = self.currentPlayer {
                    self.stop(player: player, cancelAssociation: false)
                }
            // Ignore prepare
            default:
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
            "token": latestPlayer?.payload.token
        ]
        completion(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
    }
}

// MARK: - MediaPlayerDelegate

extension TTSAgent: MediaPlayerDelegate {
    public func mediaPlayerStateDidChange(_ state: MediaPlayerState, mediaPlayer: MediaPlayable) {
        guard let player = mediaPlayer as? TTSPlayer else { return }
        log.info("media \(mediaPlayer) state: \(state)")
        
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            var ttsResult: (dialogRequestId: String, result: TTSResult)?
            var ttsState: TTSState?
            var eventTypeInfo: Event.TypeInfo?
            
            switch state {
            case .start:
                ttsState = .playing
                eventTypeInfo = .speechStarted
            case .resume, .bufferRefilled:
                ttsState = .playing
            case .finish:
                ttsResult = (dialogRequestId: player.header.dialogRequestId, result: .finished)
                ttsState = .finished
                eventTypeInfo = .speechFinished
            case .pause:
                self.stop(player: player, cancelAssociation: false)
            case .stop:
                ttsResult = (dialogRequestId: player.header.dialogRequestId, result: .stopped(cancelAssociation: player.cancelAssociation))
                ttsState = .stopped
                eventTypeInfo = .speechStopped
            case .error(let error):
                ttsResult = (dialogRequestId: player.header.dialogRequestId, result: .error(error))
                ttsState = .stopped
                eventTypeInfo = .speechStopped
            case .bufferUnderrun:
                break
            }
            
            // `TTSResult` -> `TTSState` -> `FocusState` -> Event
            if let ttsResult = ttsResult {
                self.ttsResultSubject.onNext(ttsResult)
            }
            if let ttsState = ttsState, self.latestPlayer === player {
                self.ttsState = ttsState
                switch ttsState {
                case .stopped, .finished:
                    self.releaseFocusIfNeeded()
                default:
                    break
                }
            }
            if let eventTypeInfo = eventTypeInfo {
                self.sendCompactContextEvent(Event(
                    typeInfo: eventTypeInfo,
                    token: player.payload.token,
                    playServiceId: player.payload.playServiceId,
                    referrerDialogRequestId: player.header.dialogRequestId
                ).rx)
            }
        }
    }
}

// MARK: - PlaySyncDelegate

extension TTSAgent: PlaySyncDelegate {
    public func playSyncDidRelease(property: PlaySyncProperty, messageId: String) {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard property == self.playSyncProperty,
                  let player = self.latestPlayer, player.header.messageId == messageId else { return }
            
            self.stop(player: player, cancelAssociation: true)
        }
    }
}

// MARK: - Private (Directive)

private extension TTSAgent {
    func prefetchPlay() -> PrefetchDirective {
        return { [weak self] directive in
            let player = try TTSPlayer(directive: directive)
            self?.ttsDispatchQueue.sync { [weak self] in
                guard let self = self else { return }
                
                log.debug(directive.header.messageId)
                if self.prefetchPlayer?.stop(reason: .playAnother) == true ||
                    self.currentPlayer?.stop(reason: .playAnother) == true {
                    self.ttsState = .stopped
                }
                
                self.prefetchPlayer = player
                self.focusManager.prepareFocus(channelDelegate: self)
            }
        }
    }
    
    func cancelPlay() -> CancelDirective {
        return { [weak self] directive in
            self?.ttsDispatchQueue.sync { [weak self] in
                guard let self = self else { return }
                guard let player = self.prefetchPlayer, player.header.messageId == directive.header.messageId else {
                    log.info("Message id does not match")
                    return
                }
                
                self.prefetchPlayer = nil
                self.focusManager.cancelFocus(channelDelegate: self)
            }
        }
    }
    
    func handlePlay() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
            self.ttsDispatchQueue.async { [weak self] in
                guard let self = self else {
                    completion(.canceled)
                    return
                }
                guard let player = self.prefetchPlayer, player.header.messageId == directive.header.messageId else {
                    completion(.canceled)
                    log.info("Message id does not match")
                    return
                }
                guard player.internalPlayer != nil else {
                    completion(.canceled)
                    log.info("Internal player is nil")
                    return
                }
                
                log.debug(directive.header.messageId)
                self.currentPlayer = player
                self.focusManager.requestFocus(channelDelegate: self)
                self.delegates.notify(queue: self.ttsDelegateDispatchQueue) { delegate in
                    delegate.ttsAgentDidReceive(text: player.payload.text, header: player.header)
                }
                
                self.ttsResultSubject
                    .filter { $0.dialogRequestId == player.header.dialogRequestId }
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
            
            self?.ttsDispatchQueue.async { [weak self] in
                guard let self = self, let player = self.latestPlayer else { return }
                guard player.internalPlayer != nil else {
                    // Release synchronized layer after playback finished.
                    if player.payload.playServiceId != nil {
                        self.playSyncManager.stopPlay(dialogRequestId: player.header.dialogRequestId)
                    }
                    return
                }
                
                self.stop(player: player, cancelAssociation: true)
            }
        }
    }
    
    func stop(player: TTSPlayer, cancelAssociation: Bool) {
        player.cancelAssociation = cancelAssociation
        player.stop()
    }
    
    func handleAttachment() -> HandleAttachment {
        #if DEBUG
        var totalAttachmentData = Data()
        #endif
        
        return { [weak self] attachment in
            self?.ttsDispatchQueue.async { [weak self] in
                log.info("\(attachment)")
                guard let self = self else { return }
                guard self.prefetchPlayer?.handleAttachment(attachment) == true ||
                        self.currentPlayer?.handleAttachment(attachment) == true else {
                    log.warning("MediaOpusStreamDataSource not exist or dialogRequesetId not valid")
                    return
                }
            }
            
            #if DEBUG
            totalAttachmentData.append(attachment.content)
            if attachment.isEnd {
                let attachmentFileName = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("attachment.data")
                try? totalAttachmentData.write(to: attachmentFileName)
                log.debug("attachment to file :\(attachmentFileName)")
            }
            #endif
        }
    }
}

// MARK: - Private (Event)

private extension TTSAgent {
    @discardableResult func sendCompactContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(namespace: self.capabilityAgentProperty.name),
            property: self.capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
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
