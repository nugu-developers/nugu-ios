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
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .mediaPlayer, version: "1.0")
    
    public weak var delegate: MediaPlayerAgentDelegate?
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Play", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handlePlay),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Stop", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleStop),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Search", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleSearch),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Previous", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handlePrevious),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Next", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleNext),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Move", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleMove),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Pause", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handlePause),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Resume", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleResume),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Rewind", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleRewind),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "Toggle", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleToggle),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "GetInfo", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleGetInfo)
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
        
        contextManager.add(delegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - ContextInfoDelegate

extension MediaPlayerAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: @escaping (ContextInfo?) -> Void) {
        var payload = [String: AnyHashable?]()
        
        if let context = delegate?.mediaPlayerAgentRequestContext(),
            let contextData = try? JSONEncoder().encode(context),
            let contextDictionary = try? JSONSerialization.jsonObject(with: contextData, options: []) as? [String: AnyHashable] {
            payload = contextDictionary
        }
        
        payload["version"] = capabilityAgentProperty.version
        
        completion(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
    }
}

// MARK: - Private (Directive)

private extension MediaPlayerAgent {
    func handlePlay() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let playPayload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Play.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self?.delegate?.mediaPlayerAgentReceivePlay(
                payload: playPayload,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (result) in
                    self?.processPlayDirectiveResult(payload: playPayload, result: result, referrerDialogRequestId: directive.header.dialogRequestId)
            })
        }
    }
    
    func handleStop() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payloadDictionary = directive.payloadDictionary,
                let playServiceId = payloadDictionary["playServiceId"] as? String,
                let token = payloadDictionary["token"] as? String else {
                    completion(.failed("Invalid payload"))
                    return
            }
            
            defer { completion(.finished) }
            
            self?.delegate?.mediaPlayerAgentReceiveStop(
                playServiceId: playServiceId,
                token: token,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (result) in
                    self?.processStopDirectiveResult(playServiceId: playServiceId, token: token, result: result, referrerDialogRequestId: directive.header.dialogRequestId)
            })
        }
    }
    
    func handleSearch() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let searchPayload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Search.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self?.delegate?.mediaPlayerAgentReceiveSearch(
                payload: searchPayload,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (result) in
                    self?.processSearchDirectiveResult(payload: searchPayload, result: result, referrerDialogRequestId: directive.header.dialogRequestId)
            })
        }
    }
    
    func handlePrevious() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let previousPayload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Previous.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self?.delegate?.mediaPlayerAgentReceivePrevious(
                payload: previousPayload,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (result) in
                    self?.processPreviousDirectiveResult(payload: previousPayload, result: result, referrerDialogRequestId: directive.header.dialogRequestId)
            })
        }
    }
    
    func handleNext() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let nextPayload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Next.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self?.delegate?.mediaPlayerAgentReceiveNext(
                payload: nextPayload,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (result) in
                    self?.processNextDirectiveResult(payload: nextPayload, result: result, referrerDialogRequestId: directive.header.dialogRequestId)
            })
        }
    }
    
    func handleMove() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let movePayload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Move.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self?.delegate?.mediaPlayerAgentReceiveMove(
                payload: movePayload,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (result) in
                    self?.processMoveDirectiveResult(payload: movePayload, result: result, referrerDialogRequestId: directive.header.dialogRequestId)
            })
        }
    }
    
    func handlePause() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payloadDictionary = directive.payloadDictionary,
                let playServiceId = payloadDictionary["playServiceId"] as? String,
                let token = payloadDictionary["token"] as? String else {
                    completion(.failed("Invalid payload"))
                    return
            }
            
            defer { completion(.finished) }
            
            self?.delegate?.mediaPlayerAgentReceivePause(
                playServiceId: playServiceId,
                token: token,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (result) in
                    self?.processPauseDirectiveResult(playServiceId: playServiceId, token: token, result: result, referrerDialogRequestId: directive.header.dialogRequestId)
            })
        }
    }
    
    func handleResume() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payloadDictionary = directive.payloadDictionary,
                let playServiceId = payloadDictionary["playServiceId"] as? String,
                let token = payloadDictionary["token"] as? String else {
                    completion(.failed("Invalid payload"))
                    return
            }
            
            defer { completion(.finished) }
            
            self?.delegate?.mediaPlayerAgentReceiveResume(
                playServiceId: playServiceId,
                token: token,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (result) in
                self?.processResumeDirectiveResult(playServiceId: playServiceId, token: token, result: result, referrerDialogRequestId: directive.header.dialogRequestId)
            })
        }
    }
    
    func handleRewind() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payloadDictionary = directive.payloadDictionary,
                let playServiceId = payloadDictionary["playServiceId"] as? String,
                let token = payloadDictionary["token"] as? String else {
                    completion(.failed("Invalid payload"))
                    return
            }
            
            defer { completion(.finished) }
            
            self?.delegate?.mediaPlayerAgentReceiveRewind(
                playServiceId: playServiceId,
                token: token,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (result) in
                    self?.processRewindDirectiveResult(playServiceId: playServiceId, token: token, result: result, referrerDialogRequestId: directive.header.dialogRequestId)
            })
        }
    }
    
    func handleToggle() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let togglePayload = try? JSONDecoder().decode(MediaPlayerAgentDirectivePayload.Toggle.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            
            defer { completion(.finished) }
            
            self?.delegate?.mediaPlayerAgentReceiveToggle(
                payload: togglePayload,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (result) in
                    self?.processToggleDirectiveResult(payload: togglePayload, result: result, referrerDialogRequestId: directive.header.dialogRequestId)
            })
        }
    }
    
    func handleGetInfo() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let payloadDictionary = directive.payloadDictionary,
                let playServiceId = payloadDictionary["playServiceId"] as? String,
                let token = payloadDictionary["token"] as? String else {
                    completion(.failed("Invalid payload"))
                    return
            }
            
            defer { completion(.finished) }
            
            self?.delegate?.mediaPlayerAgentReceiveGetInfo(
                playServiceId: playServiceId,
                token: token,
                dialogRequestId: directive.header.dialogRequestId,
                completion: { [weak self] (result) in
                    self?.processGetInfoDirectiveResult(playServiceId: playServiceId, token: token, result: result, referrerDialogRequestId: directive.header.dialogRequestId)
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
        playServiceId: String,
        token: String,
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
            playServiceId: playServiceId,
            token: token,
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
        playServiceId: String,
        token: String,
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
            playServiceId: playServiceId,
            token: token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processResumeDirectiveResult(
        playServiceId: String,
        token: String,
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
            playServiceId: playServiceId,
            token: token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
    
    func processRewindDirectiveResult(
        playServiceId: String,
        token: String,
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
            playServiceId: playServiceId,
            token: token,
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
        playServiceId: String,
        token: String,
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
            playServiceId: playServiceId,
            token: token,
            referrerDialogRequestId: referrerDialogRequestId
        ).rx)
    }
}
