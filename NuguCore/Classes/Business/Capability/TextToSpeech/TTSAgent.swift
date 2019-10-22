//
//  TTSAgent.swift
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

final public class TTSAgent: TTSAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .textToSpeech, version: "1.0")
    
    private let ttsDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.tts_agent", qos: .userInitiated)
    
    public var focusManager: FocusManageable!
    public var channel: FocusChannelConfigurable!
    public var mediaPlayerFactory: MediaPlayableFactory!
    public var messageSender: MessageSendable!
    public var playSyncManager: PlaySyncManageable!
    
    private let delegates = DelegateSet<TTSAgentDelegate>()
    
    private var focusState: FocusState = .nothing
    private var ttsState: TTSState = .finished {
        didSet {
            log.info("\(oldValue) \(ttsState)")
            guard oldValue != ttsState else { return }
            
            // Release Focus
            switch ttsState {
            case .idle, .stopped, .finished:
                if let media = currentMedia,
                    let playServiceId = media.payload.playServiceId {
                    currentMedia = nil
                    playSyncManager.releaseSync(delegate: self, dialogRequestId: media.dialogRequestId, playServiceId: playServiceId)
                }
            case .playing:
                if let media = currentMedia,
                    let playServiceId = media.payload.playServiceId {
                    playSyncManager.startSync(delegate: self, dialogRequestId: media.dialogRequestId, playServiceId: playServiceId)
                }
            }
            
            delegates.notify { delegate in
                delegate.ttsAgentDidChange(state: ttsState)
            }
        }
    }
    private let ttsResultSubject = PublishSubject<(dialogRequestId: String, result: TTSResult)>()
    
    // Current play Info
    private var currentMedia: TTSMedia? {
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
    
    private let disposeBag = DisposeBag()
    
    public init() {
        log.info("")
        ttsResultSubject.subscribe(onNext: { [weak self] (_, result) in
            // Send error
            switch result {
            case .error(let error):
                self?.messageSender.sendCrashReport(error: error)
            default: break
            }
        }).disposed(by: disposeBag)
    }
    
    deinit {
        log.info("")
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
            
            let typeInfo: Event.TypeInfo = .speechPlay(text: text)
            let event = Event(token: nil, playServiceId: playServiceId, typeInfo: typeInfo)
            let dialogRequestId = TimeUUID().hexString
            self.sendEvent(
                event,
                context: self.provideContext(),
                dialogRequestId: dialogRequestId,
                by: self.messageSender
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
    
    func stopTTS(cancelAssociated: Bool) {
        currentMedia?.cancelAssociated = cancelAssociated
        stop()
    }
}

// MARK: - HandleDirectiveDelegate

extension TTSAgent: HandleDirectiveDelegate {
    public func handleDirectiveTypeInfos() -> DirectiveTypeInfos {
        return DirectiveTypeInfo.allDictionaryCases
    }
    
    public func handleDirectivePrefetch(
        _ directive: DirectiveProtocol,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        log.info("\(directive.header.type)")
        
        switch directive.header.type {
        case DirectiveTypeInfo.speak.type:
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
        
        guard let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self) else {
            completionHandler(.failure(HandleDirectiveError.handleDirectiveError(message: "Unknown directive")))
            return
        }
        
        switch directiveTypeInfo {
        case .speak:
            // Speak 는 재생 완료 후 handler 호출
            play(directive: directive, completionHandler: completionHandler)
        case .stop:
            completionHandler(stop())
        }
    }
    
    public func handleAttachment(_ attachment: AttachmentProtocol) {
        log.info("\(attachment.header.messageID)")
        
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let media = self.currentMedia, media.dialogRequestId == attachment.header.dialogRequestID else {
                log.warning("TextToSpeechItem not exist or dialogRequesetId not valid")
                return
            }
            
            do {
                try media.player.appendData(attachment.content)
                
                if attachment.isEnd {
                    try media.player.lastDataAppended()
                }
            } catch {
                self.messageSender.sendCrashReport(error: error)
                log.error(error)
            }
        }
    }
}

// MARK: - FocusChannelDelegate

extension TTSAgent: FocusChannelDelegate {
    public func focusChannelConfiguration() -> FocusChannelConfigurable {
        return channel
    }
    
    public func focusChannelDidChange(focusState: FocusState) {
        log.info("\(focusState) \(ttsState)")
        self.focusState = focusState
        
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch (focusState, self.ttsState) {
            case (.foreground, let ttsState) where [.idle, .stopped, .finished].contains(ttsState):
                self.currentMedia?.player.play()
            // Foreground. playing 무시
            case (.foreground, _):
                break
            case (.background, .playing):
                self.stop()
            // background. idle, stopped, finished 무시
            case (.background, _):
                break
            case (.nothing, .playing):
                self.stop()
            // none. idle/stopped/finished 무시
            case (.nothing, _):
                break
            }
        }
    }
}

// MARK: - ProvideContextDelegate

extension TTSAgent: ProvideContextDelegate {
    public func provideContext() -> ContextInfo {
        let payload: [String: Any] = [
            "ttsActivity": ttsState.value,
            "version": capabilityAgentProperty.version,
            "engine": "skt"
        ]
        
        return ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload)
    }
}

// MARK: - MediaPlayerDelegate

extension TTSAgent: MediaPlayerDelegate {
    public func mediaPlayerDidChange(state: MediaPlayerState) {
        log.info(state)
        
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let media = self.currentMedia else { return }
            
            if let eventInfo = state.eventTypeInfo {
                self.sendEvent(info: eventInfo)
            }
            
            switch state {
            case .start, .resume, .bufferRefilled:
                self.ttsState = .playing
            case .finish:
                self.ttsResultSubject.onNext((dialogRequestId: media.dialogRequestId, result: .finished))
                self.ttsState = .finished
            case .pause:
                media.player.stop()
            case .stop:
                self.ttsResultSubject.onNext(
                    (dialogRequestId: media.dialogRequestId, result: .stopped(cancelAssociated: media.cancelAssociated))
                )
                self.ttsState = .stopped
            case .bufferUnderrun:
                break
            case .error(let error):
                self.ttsResultSubject.onNext((dialogRequestId: media.dialogRequestId, result: .error(error)))
                self.ttsState = .stopped
            }
        }
    }
}

// MARK: - PlaySyncDelegate

extension TTSAgent: PlaySyncDelegate {
    public func playSyncIsDisplay() -> Bool {
        return false
    }
    
    public func playSyncDuration() -> DisplayTemplate.Common.Duration {
        return .short
    }
    
    public func playSyncDidChange(state: PlaySyncState, dialogRequestId: String) {
        log.info("\(state)")
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            if case .released = state,
                let media = self.currentMedia, media.dialogRequestId == dialogRequestId {
                self.stopSilently()
                self.currentMedia = nil
            }
        }
    }
}

// MARK: - VolumeControllerDelegate

extension TTSAgent: VolumeControllerDelegate {
    public func volumeControllerType() -> VolumeControllerType {
        return .nugu
    }
    
    public func volumeControllerIsMuted() -> Bool {
        return playerIsMuted
    }
    
    public func volumeControllerDidChange(muted: Bool) -> Bool {
        playerIsMuted = muted
        return true
    }
}

// MARK: - Private (Directive)

private extension TTSAgent {
    func prefetchPlay(directive: DirectiveProtocol, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            let result = Result<Void, Error> (catching: {
                guard let data = directive.payload.data(using: .utf8) else {
                    throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
                }
                
                let payload = try JSONDecoder().decode(TTSMedia.Payload.self, from: data)
                guard case .attachment = payload.sourceType else {
                    throw HandleDirectiveError.handleDirectiveError(message: "Not supported sourceType")
                }
                
                self.stopSilently()
                
                let mediaPlayer = self.mediaPlayerFactory.makeMediaPlayer(type: .voice)
                mediaPlayer.delegate = self
                mediaPlayer.isMuted = self.playerIsMuted
                self.currentMedia = TTSMedia(
                    player: mediaPlayer,
                    payload: payload,
                    dialogRequestId: directive.header.dialogRequestID
                )
                if let playServiceId = payload.playServiceId {
                    self.playSyncManager.prepareSync(delegate: self, dialogRequestId: directive.header.dialogRequestID, playServiceId: playServiceId)
                }
            })
            
            completionHandler(result)
        }
    }
    
    func play(directive: DirectiveProtocol, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let media = self.currentMedia else { return }
            
            self.delegates.notify { delegate in
                delegate.ttsAgentDidReceive(text: media.payload.text)
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
    
    @discardableResult func stop() -> Result<Void, Error> {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self, let media = self.currentMedia else { return }

            media.player.stop()
            if let playServiceId = media.payload.playServiceId, media.cancelAssociated == true {
                self.playSyncManager.releaseSyncImmediately(dialogRequestId: media.dialogRequestId, playServiceId: playServiceId)
            }
        }
        return .success(())
    }
    
    /// Stop previously playing TTS
    func stopSilently() {
        guard let media = currentMedia, case .playing = ttsState else { return }
        media.player.delegate = nil
        media.player.stop()
        sendEvent(info: .speechStopped)
        ttsResultSubject.onNext(
            (dialogRequestId: media.dialogRequestId, result: .stopped(cancelAssociated: media.cancelAssociated))
        )
        ttsState = .stopped
    }
}

// MARK: - Private (Event)

private extension TTSAgent {
    func sendEvent(info: Event.TypeInfo) {
        guard let media = currentMedia,
            let playServiceId = media.payload.playServiceId else {
            log.error("TextToSpeechItem not exist")
            return
        }
        
        sendEvent(
            Event(
                token: media.payload.token,
                playServiceId: playServiceId,
                typeInfo: info
            ),
            context: provideContext(),
            dialogRequestId: TimeUUID().hexString,
            by: messageSender
        )
    }
}

// MARK: - Private(FocusManager)

private extension TTSAgent {
    func releaseFocus() {
        guard focusState != .nothing else { return }
        focusManager.releaseFocus(channelDelegate: self)
    }
}

// MARK: - MediaPlayerState + EventTypeInfo

private extension MediaPlayerState {
    var eventTypeInfo: TTSAgent.Event.TypeInfo? {
        switch self {
        case .bufferRefilled, .bufferUnderrun:
            return nil
        case .start:
            return .speechStarted
        case .stop:
            return .speechStopped
        case .pause:
            return nil
        case .resume:
            return nil
        case .finish:
            return .speechFinished
        case .error:
            return .speechStopped
        }
    }
}
