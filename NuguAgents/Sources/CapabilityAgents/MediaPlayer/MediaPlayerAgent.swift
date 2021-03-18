//
//  MediaPlayerAgent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/07/06.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

public final class MediaPlayerAgent: MediaPlayerAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .mediaPlayer, version: "1.1")
    
    public weak var delegate: MediaPlayerAgentDelegate?
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Play", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handlePlay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Stop", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleStop),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Search", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSearch),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Previous", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handlePrevious),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Next", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleNext),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Move", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleMove),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Pause", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handlePause),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Resume", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleResume),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Rewind", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: false), directiveHandler: handleRewind),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Toggle", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleToggle),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "GetInfo", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleGetInfo),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "HandlePlaylist", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handlePlaylist),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "HandleLyrics", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleLyrics)
    ]
    
    private lazy var disposeBag = DisposeBag()
    
    public init(
        directiveSequencer: DirectiveSequenceable,
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable
    ) {
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
        
        contextManager.addProvider(contextInfoProvider)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        var payload = [String: AnyHashable?]()
        payload["version"] = self.capabilityAgentProperty.version
        
        if let context = self.delegate?.mediaPlayerAgentRequestContext(),
            let contextData = try? JSONEncoder().encode(context),
            let contextDictionary = try? JSONSerialization.jsonObject(with: contextData, options: []) as? [String: AnyHashable] {
            payload = contextDictionary
        }
        
        completion(ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
    }
}

// MARK: - Private (Directive)

private extension MediaPlayerAgent {
    func handlePlay() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let playPayload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Play.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceivePlay(
                payload: playPayload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processPlayDirectiveResult(
                        payload: playPayload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handleStop() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Stop.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceiveStop(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processStopDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handleSearch() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Search.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceiveSearch(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processSearchDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handlePrevious() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Previous.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceivePrevious(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processPreviousDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handleNext() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Next.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceiveNext(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processNextDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handleMove() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Move.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceiveMove(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processMoveDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handlePause() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Pause.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceivePause(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processPauseDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handleResume() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Resume.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceiveResume(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processResumeDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handleRewind() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Rewind.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceiveRewind(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processRewindDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handleToggle() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Toggle.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceiveToggle(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processToggleDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handleGetInfo() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.GetInfo.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceiveGetInfo(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processGetInfoDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handlePlaylist() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.HandlePlaylist.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceiveHandlePlaylist(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processHandlePlaylistDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
    
    func handleLyrics() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let self = self, let delegate = self.delegate else {
                completion(.canceled)
                return
            }
            
            guard let payload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.HandleLyrics.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            delegate.mediaPlayerAgentReceiveHandleLyrics(
                payload: payload,
                header: directive.header,
                completion: { [weak self] (result) in
                    self?.processHandleLyricsDirectiveResult(
                        payload: payload,
                        result: result,
                        referrerDialogRequestId: directive.header.dialogRequestId
                    )
            })
        }
    }
}

// MARK: - Private(Event)

private extension MediaPlayerAgent {
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

// MARK: - Private(Process directive)

private extension MediaPlayerAgent {
    func processPlayDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.Play,
        result: MediaPlayerAgentProcessResult.Play,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded(let message):
            typeInfo = .playSucceeded(message: message)
        case .suspended(let song, let playlist, let issueCode):
            typeInfo = .playSuspended(song: song, playlist: playlist, issueCode: issueCode, data: payload.data)
        case .failed(let errorCode):
            typeInfo = .playFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(Event(
            typeInfo: typeInfo,
            playServiceId: payload.playServiceId,
            token: payload.token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processStopDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.Stop,
        result: MediaPlayerAgentProcessResult.Stop,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded:
            typeInfo = .stopSucceeded
        case .failed(let errorCode):
            typeInfo = .stopFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(Event(
            typeInfo: typeInfo,
            playServiceId: payload.playServiceId,
            token: payload.token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processSearchDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.Search,
        result: MediaPlayerAgentProcessResult.Search,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded(let message):
            typeInfo = .searchSucceeded(message: message)
        case .failed(let errorCode):
            typeInfo = .searchFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(Event(
            typeInfo: typeInfo,
            playServiceId: payload.playServiceId,
            token: payload.token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processPreviousDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.Previous,
        result: MediaPlayerAgentProcessResult.Previous,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded(let message):
            typeInfo = .previousSucceeded(message: message)
        case .suspended(let song, let playlist, let target):
            typeInfo = .previousSuspended(song: song, playlist: playlist, target: target, data: payload.data)
        case .failed(let errorCode):
            typeInfo = .previousFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(Event(
            typeInfo: typeInfo,
            playServiceId: payload.playServiceId,
            token: payload.token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processNextDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.Next,
        result: MediaPlayerAgentProcessResult.Next,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded(let message):
            typeInfo = .nextSucceeded(message: message)
        case .suspended(let song, let playlist, let target):
            typeInfo = .nextSuspended(song: song, playlist: playlist, target: target, data: payload.data)
        case .failed(let errorCode):
            typeInfo = .nextFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(Event(
            typeInfo: typeInfo,
            playServiceId: payload.playServiceId,
            token: payload.token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processMoveDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.Move,
        result: MediaPlayerAgentProcessResult.Move,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded(let messasge):
            typeInfo = .moveSucceeded(message: messasge)
        case .failed(let errorCode):
            typeInfo = .moveFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(Event(
            typeInfo: typeInfo,
            playServiceId: payload.playServiceId,
            token: payload.token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processPauseDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.Pause,
        result: MediaPlayerAgentProcessResult.Pause,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded(let messasge):
            typeInfo = .pauseSucceeded(message: messasge)
        case .failed(let errorCode):
            typeInfo = .pauseFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(Event(
            typeInfo: typeInfo,
            playServiceId: payload.playServiceId,
            token: payload.token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processResumeDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.Resume,
        result: MediaPlayerAgentProcessResult.Resume,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded(let messasge):
            typeInfo = .resumeSucceeded(message: messasge)
        case .failed(let errorCode):
            typeInfo = .resumeFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(Event(
            typeInfo: typeInfo,
            playServiceId: payload.playServiceId,
            token: payload.token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processRewindDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.Rewind,
        result: MediaPlayerAgentProcessResult.Rewind,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded(let messasge):
            typeInfo = .rewindSucceeded(message: messasge)
        case .failed(let errorCode):
            typeInfo = .rewindFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(Event(
            typeInfo: typeInfo,
            playServiceId: payload.playServiceId,
            token: payload.token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processToggleDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.Toggle,
        result: MediaPlayerAgentProcessResult.Toggle,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded(let message):
            typeInfo = .toggleSucceeded(message: message)
        case .failed(let errorCode):
            typeInfo = .toggleFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(Event(
            typeInfo: typeInfo,
            playServiceId: payload.playServiceId,
            token: payload.token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processGetInfoDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.GetInfo,
        result: MediaPlayerAgentProcessResult.GetInfo,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded(let song, let issueDate, let playTime, let playListName):
            typeInfo = .getInfoSucceeded(song: song, issueDate: issueDate, playTime: playTime, playListName: playListName)
        case .failed(let errorCode):
            typeInfo = .getInfoFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(Event(
            typeInfo: typeInfo,
            playServiceId: payload.playServiceId,
            token: payload.token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processHandlePlaylistDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.HandlePlaylist,
        result: MediaPlayerAgentProcessResult.HandlePlaylist,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded:
            typeInfo = .handlePlaylistSucceeded
        case .failed(let errorCode):
            typeInfo = .handlePlaylistFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(
            Event(
                typeInfo: typeInfo,
                playServiceId: payload.playServiceId,
                token: nil,
                referrerDialogRequestId: referrerDialogRequestId
            ).rx
        )
    }
    
    func processHandleLyricsDirectiveResult(
        payload: MediaPlayerAgentDirectivePayload.HandleLyrics,
        result: MediaPlayerAgentProcessResult.HandleLyrics,
        referrerDialogRequestId: String
    ) {
        let typeInfo: MediaPlayerAgent.Event.TypeInfo
        switch result {
        case .succeeded:
            typeInfo = .handleLyricsSucceeded
        case .failed(let errorCode):
            typeInfo = .handleLyricsFailed(errorCode: errorCode)
        }
        
        sendCompactContextEvent(
            Event(
                typeInfo: typeInfo,
                playServiceId: payload.playServiceId,
                token: nil,
                referrerDialogRequestId: referrerDialogRequestId
            ).rx
        )
    }
}
