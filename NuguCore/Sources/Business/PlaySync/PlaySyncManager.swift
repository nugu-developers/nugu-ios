//
//  PlaySyncManager.swift
//  NuguCore
//
//  Created by MinChul Lee on 2019/07/16.
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

import RxSwift

public class PlaySyncManager: PlaySyncManageable {
    private let playSyncDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.play_sync", qos: .userInitiated)
    private lazy var playSyncScheduler = SerialDispatchQueueScheduler(
        queue: playSyncDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.play_sync"
    )
    
    private let delegates = DelegateSet<PlaySyncDelegate>()
    
    private var displayTimerDisposeBag = DisposeBag()
    private var soundTimerDisposeBag = DisposeBag()
    
    private var playContexts = [PlaySyncLayerType: [PlaySyncContextType: PlaySyncInfo]]()
    private var playContextInfos: [PlaySyncInfo] { playContexts.flatMap { $1 }.compactMap { $0.value } }
    private var playContextTimers = [PlaySyncLayerType: [PlaySyncContextType: DisposeBag]]()
    private var playStack = [String]()
    
    public init(contextManager: ContextManageable) {
        log.debug("initiated")
        contextManager.add(provideContextDelegate: self)
    }
    
    deinit {
        log.debug("deinitiated")
    }
}

// MARK: - PlaySyncManageable

public extension PlaySyncManager {
    func add(delegate: PlaySyncDelegate) {
        delegates.add(delegate)
    }
    
    func remove(delegate: PlaySyncDelegate) {
        delegates.remove(delegate)
    }
    
    func startPlay(layerType: PlaySyncLayerType, contextType: PlaySyncContextType, duration: DispatchTimeInterval, playServiceId: String?) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let playServiceId = playServiceId else { return }
            
            // Push to play stack
            self.pushToPlayStack(layerType: layerType, contextType: contextType, duration: duration, playServiceId: playServiceId)

            // Cancel timers
            self.cancelTimer(layerType: layerType)
            
            // Start display timer
            if contextType == .display {
                self.startTimer(layerType: layerType, contextType: contextType, duration: duration)
            }
        }
    }
    
    func endPlay(layerType: PlaySyncLayerType, contextType: PlaySyncContextType) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let playLayer = self.playContexts[layerType] else { return }
            
            // Start timers
            if let info = playLayer[.display] {
                self.startTimer(layerType: layerType, contextType: .display, duration: info.duration)
            }
            if let info = playLayer[.sound] {
                self.startTimer(layerType: layerType, contextType: .sound, duration: info.duration)
            }
            
            // Multi-layer exceptions
            if self.hasMultiLayer() {
                // Cancel timers
                self.cancelTimer(layerType: layerType, contextType: contextType)
                // Pop from play stack
                self.popFromPlayStack(layerType: layerType, contextType: contextType)
            }
        }
    }
    
    func stopPlay(layerType: PlaySyncLayerType) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel timers
            self.cancelTimer(layerType: layerType)

            // Pop from play stack
            self.popFromPlayStack(layerType: layerType, contextType: .display)
            self.popFromPlayStack(layerType: layerType, contextType: .sound)
        }
    }
    
    func resetTimer(layerType: PlaySyncLayerType) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let playLayer = self.playContexts[layerType] else { return }
            
            // Cancel timers
            self.cancelTimer(layerType: layerType)
            
            // Start timers
            if let info = playLayer[.display] {
                self.startTimer(layerType: layerType, contextType: .display, duration: info.duration)
            }
            if let info = playLayer[.sound] {
                self.startTimer(layerType: layerType, contextType: .sound, duration: info.duration)
            }
        }
    }
}

// MARK: - ContextInfoDelegate
extension PlaySyncManager: ContextInfoDelegate {
    public func contextInfoRequestContext(completionHandler: (ContextInfo?) -> Void) {
        completionHandler(ContextInfo(contextType: .client, name: "playStack", payload: playStack))
    }
}

// MARK: - Private

private extension PlaySyncManager {
    func pushToPlayStack(layerType: PlaySyncLayerType, contextType: PlaySyncContextType, duration: DispatchTimeInterval, playServiceId: String) {
        let info = PlaySyncInfo(playServiceId: playServiceId, playSyncState: .synced, duration: duration)
        
        var playLayer = playContexts[layerType] ?? [:]
        playLayer[contextType] = info
        playContexts[layerType] = playLayer

        playStack.removeAll { $0 == playServiceId }
        playStack.insert(playServiceId, at: 0)
        
        delegates.notify { (delegate) in
            delegate.playSyncDidChange(state: .synced, layerType: layerType, contextType: contextType, playServiceId: playServiceId)
        }
        
        log.debug(playContexts)
        log.debug(playStack)
    }
    
    func popFromPlayStack(layerType: PlaySyncLayerType, contextType: PlaySyncContextType) {
        guard let info = playContexts[layerType]?.removeValue(forKey: contextType) else { return }

        if playContexts[layerType]?.isEmpty == true {
            playContexts[layerType] = nil
        }
        
        if playContextInfos.contains(where: { $0.playServiceId == info.playServiceId }) == false {
            playStack.removeAll { $0 == info.playServiceId }
        }
        
        delegates.notify { (delegate) in
            delegate.playSyncDidChange(state: .released, layerType: layerType, contextType: contextType, playServiceId: info.playServiceId)
        }
        
        log.debug(playContexts)
        log.debug(playStack)
    }
    
    func startTimer(layerType: PlaySyncLayerType, contextType: PlaySyncContextType, duration: DispatchTimeInterval) {
        log.debug("Start layerType \(layerType) contextType \(contextType) duration \(duration)")
        let disposeBag = DisposeBag()
        Completable.create { [weak self] (event) -> Disposable in
            guard let self = self else { return Disposables.create() }

            log.debug("End layerType \(layerType) contextType \(contextType) duration \(duration)")
            self.popFromPlayStack(layerType: layerType, contextType: contextType)
            
            event(.completed)
            return Disposables.create()
        }
        .delaySubscription(duration, scheduler: playSyncScheduler)
        .subscribe()
        .disposed(by: disposeBag)
        
        var playLayerTimer = playContextTimers[layerType] ?? [:]
        playLayerTimer[contextType] = disposeBag
        
        playContextTimers[layerType] = playLayerTimer
    }

    func cancelTimer(layerType: PlaySyncLayerType) {
        log.debug("layerType \(layerType)")
        playContextTimers[layerType] = nil
    }
    
    func cancelTimer(layerType: PlaySyncLayerType, contextType: PlaySyncContextType) {
        log.debug("layerType \(layerType) contextType \(contextType)")
        playContextTimers[layerType]?[contextType] = nil
        
        if playContextTimers[layerType]?.isEmpty == true {
            playContextTimers[layerType] = nil
        }
    }
    
    func hasMultiLayer() -> Bool {
        return playContexts.count > 1
    }
}
