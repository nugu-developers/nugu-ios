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
    
    private var playStack = PlayStack()
    private var playContextTimers = [PlaySyncProperty: DisposeBag]()
    
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
        guard let playServiceId = playServiceId else { return }
        
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }

            log.debug("\(property) \(playServiceId)")
            
            // Push to play stack
            self.pushToPlayStack(property: property, duration: duration, playServiceId: playServiceId, dialogRequestId: dialogRequestId)
            
            let playGroup = self.playStack.playGroup(layerType: property.layerType, dialogRequestId: dialogRequestId)
            // Cancel timers
            log.debug("Cancel layer timer \(playGroup)")
            playGroup.forEach(self.removeTimer)
            
            // Start display only timer
            if property.contextType == .display && playGroup.count == 1 {
                log.debug("Add display only timer \(property) \(duration)")
                self.addTimer(property: property, duration: duration)
            }
        }
    }
    
    func endPlay(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let info = self.playStack[property] else { return }
            
            log.debug("\(property) \(info.playServiceId)")
            
            // Set timers
            let playGroup = self.playStack.playGroup(layerType: property.layerType, dialogRequestId: info.dialogRequestId)
            log.debug("Start layer timer \(playGroup)")
            playGroup.forEach {
                guard let duration = self.playStack[$0]?.duration else { return }
                self.addTimer(property: $0, duration: duration)
            }
            
            // Multi-layer exceptions
            if self.playStack.multiLayerSynced {
                // Pop from play stack
                self.popFromPlayStack(property: property)
            }
        }
    }
    
    func stopPlay(dialogRequestId: String) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }

            log.debug(dialogRequestId)
            
            // Pop from play stack
            self.playStack.playGroup(dialogRequestId: dialogRequestId).forEach(self.popFromPlayStack)
        }
    }
    
    func startTimer(property: PlaySyncProperty, duration: DispatchTimeInterval) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.playStack[property] != nil else { return }
            
            log.debug("\(property) \(duration)")
            
            // Cancel timers
            self.removeTimer(property: property)

            // Start timers
            self.addTimer(property: property, duration: duration)
        }
    }
    
    func resetTimer(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.playContextTimers[property] != nil else { return }
            guard let info = self.playStack[property] else { return }
            
            log.debug("\(property) \(info.duration)")
            
            // Cancel timers
            self.removeTimer(property: property)

            // Start timers
            self.addTimer(property: property, duration: info.duration)
        }
    }
    
    func cancelTimer(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.playContextTimers[property] != nil else { return }
            
            log.debug(property)
            
            // Cancel timers
            self.playContextTimers[property] = DisposeBag()
        }
    }
}

// MARK: - ContextInfoDelegate
extension PlaySyncManager: ContextInfoDelegate {
    public func contextInfoRequestContext(completionHandler: (ContextInfo?) -> Void) {
        log.debug("\(playStack.playServiceIds)")
        completionHandler(ContextInfo(contextType: .client, name: "playStack", payload: playStack.playServiceIds))
    }
}

// MARK: - Private

private extension PlaySyncManager {
    func pushToPlayStack(property: PlaySyncProperty, duration: DispatchTimeInterval, playServiceId: String, dialogRequestId: String) {
        // Cancel timers
        removeTimer(property: property)

        playStack[property] = PlaySyncInfo(playServiceId: playServiceId, dialogRequestId: dialogRequestId, duration: duration)
    }
    
    func popFromPlayStack(property: PlaySyncProperty) {
        guard let info = playStack[property] else { return }
        
        // Cancel timers
        removeTimer(property: property)
        
        playStack[property] = nil
        
        delegates.notify { (delegate) in
            delegate.playSyncDidRelease(property: property, dialogRequestId: info.dialogRequestId)
        }
    }
    
    func addTimer(property: PlaySyncProperty, duration: DispatchTimeInterval) {
        guard duration != .never else { return }
        
        let disposeBag = DisposeBag()
        Completable.create { [weak self] (event) -> Disposable in
            guard let self = self else { return Disposables.create() }

            log.debug("Timer fired. \(property) duration \(duration)")
            self.popFromPlayStack(property: property)
            
            event(.completed)
            return Disposables.create()
        }
        .delaySubscription(duration, scheduler: playSyncScheduler)
        .subscribe()
        .disposed(by: disposeBag)
        
        playContextTimers[property] = disposeBag
    }
    
    func removeTimer(property: PlaySyncProperty) {
        playContextTimers[property] = nil
    }
}
