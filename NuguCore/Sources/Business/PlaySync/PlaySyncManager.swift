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
    
    private var playContexts = [PlaySyncProperty.LayerType: [PlaySyncProperty.ContextType: PlaySyncInfo]]()
    private var playContextInfos: [PlaySyncInfo] { playContexts.flatMap { $1 }.compactMap { $0.value } }
    private var playContextTimers = [PlaySyncProperty.LayerType: [PlaySyncProperty.ContextType: DisposeBag]]()
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
    
    func startPlay(property: PlaySyncProperty, duration: DispatchTimeInterval, playServiceId: String?, dialogRequestId: String) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let playServiceId = playServiceId else { return }
            
            log.debug(property)
            
            // Push to play stack
            self.pushToPlayStack(property: property, duration: duration, playServiceId: playServiceId, dialogRequestId: dialogRequestId)

            // Cancel timers
            self.cancelTimer(layerType: property.layerType)
            
            // Start display only timer
            if property.contextType == .display && self.playContexts[property.layerType]?[.sound] == nil {
                self.startTimer(property: property, duration: duration)
            }
        }
    }
    
    func endPlay(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let playLayer = self.playContexts[property.layerType] else { return }
            
            log.debug(property)
            
            // Start timers
            if let info = playLayer[.display] {
                self.startTimer(property: property, duration: info.duration)
            }
            if let info = playLayer[.sound] {
                self.startTimer(property: property, duration: info.duration)
            }
            
            // Multi-layer exceptions
            if self.hasMultiLayer() {
                // Cancel timers
                self.cancelTimer(property: property)
                // Pop from play stack
                self.popFromPlayStack(property: property)
            }
        }
    }
    
    func stopPlay(dialogRequestId: String) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }

            log.debug(dialogRequestId)
            self.playContexts.forEach { (layerType, playLayer) in
                playLayer.forEach { (contextType, info) in
                    if info.dialogRequestId == dialogRequestId {
                        let property = PlaySyncProperty(layerType: layerType, contextType: contextType)
                        
                        // Cancel timers
                        self.cancelTimer(property: property)
                        // Pop from play stack
                        self.popFromPlayStack(property: property)
                    }
                }
            }
        }
    }
    
    func resetTimer(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let info = self.playContexts[property.layerType]?[property.contextType] else { return }
            guard self.playContextTimers[property.layerType]?[property.contextType] != nil else { return }

            log.debug(property)
            
            // Cancel timers
            self.cancelTimer(property: property)

            // Start timers
            self.startTimer(property: property, duration: info.duration)
        }
    }
}

// MARK: - ContextInfoDelegate
extension PlaySyncManager: ContextInfoDelegate {
    public func contextInfoRequestContext(completionHandler: (ContextInfo?) -> Void) {
        log.debug(playStack)
        completionHandler(ContextInfo(contextType: .client, name: "playStack", payload: playStack))
    }
}

// MARK: - Private

private extension PlaySyncManager {
    func pushToPlayStack(property: PlaySyncProperty, duration: DispatchTimeInterval, playServiceId: String, dialogRequestId: String) {
        let info = PlaySyncInfo(playServiceId: playServiceId, dialogRequestId: dialogRequestId, playSyncState: .synced, duration: duration)
        
        var playLayer = playContexts[property.layerType] ?? [:]
        playLayer[property.contextType] = info
        playContexts[property.layerType] = playLayer
        
        playStack.removeAll { id in
            id == playServiceId || playContextInfos.contains(where: { $0.playServiceId == id }) == false
        }
        playStack.insert(playServiceId, at: 0)
        
        delegates.notify { (delegate) in
            delegate.playSyncDidChange(state: .synced, property: property, playServiceId: playServiceId)
        }
        
        log.debug(playContexts)
        log.debug(playStack)
    }
    
    func popFromPlayStack(property: PlaySyncProperty) {
        guard let info = playContexts[property.layerType]?.removeValue(forKey: property.contextType) else { return }

        if playContexts[property.layerType]?.isEmpty == true {
            playContexts[property.layerType] = nil
        }
        
        playStack.removeAll { playServiceId in
            playContextInfos.contains(where: { $0.playServiceId == playServiceId }) == false
        }
        
        delegates.notify { (delegate) in
            delegate.playSyncDidChange(state: .released, property: property, playServiceId: info.playServiceId)
        }
        
        log.debug(playContexts)
        log.debug(playStack)
    }
    
    func startTimer(property: PlaySyncProperty, duration: DispatchTimeInterval) {
        log.debug("Start \(property) duration \(duration)")
        let disposeBag = DisposeBag()
        Completable.create { [weak self] (event) -> Disposable in
            guard let self = self else { return Disposables.create() }

            log.debug("End \(property) duration \(duration)")
            self.popFromPlayStack(property: property)
            
            event(.completed)
            return Disposables.create()
        }
        .delaySubscription(duration, scheduler: playSyncScheduler)
        .subscribe()
        .disposed(by: disposeBag)
        
        var playLayerTimer = playContextTimers[property.layerType] ?? [:]
        playLayerTimer[property.contextType] = disposeBag
        
        playContextTimers[property.layerType] = playLayerTimer
    }

    func cancelTimer(layerType: PlaySyncProperty.LayerType) {
        log.debug(layerType)
        playContextTimers[layerType] = nil
    }
    
    func cancelTimer(property: PlaySyncProperty) {
        log.debug(property)
        playContextTimers[property.layerType]?[property.contextType] = nil
        
        if playContextTimers[property.layerType]?.isEmpty == true {
            playContextTimers[property.layerType] = nil
        }
    }
    
    func hasMultiLayer() -> Bool {
        return playContexts.count > 1
    }
}
