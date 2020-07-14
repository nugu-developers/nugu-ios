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
        contextManager.add(delegate: self)
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
    
    func startPlay(property: PlaySyncProperty, info: PlaySyncInfo) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }

            log.debug("\(property) \(info)")
            
            // Push to play stack
            self.pushToPlayStack(property: property, info: info)
            
            // Cancel timers
            let timerGroup = self.playStack.playGroup(layerType: property.layerType, playServiceId: info.playServiceId)
            log.debug("Cancel layer timer \(timerGroup)")
            timerGroup.forEach(self.removeTimer)
            
            // Start display only timer
            let directiveGroup = self.playStack.playGroup(dialogRequestId: info.dialogRequestId)
            if property.contextType == .display && directiveGroup.count == 1 {
                log.debug("Add display only timer \(property) \(info.duration)")
                self.addTimer(property: property, duration: info.duration)
            }
        }
    }
    
    func endPlay(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let play = self.playStack[property] else { return }
            
            log.debug("\(property) \(play)")
            
            // Set timers
            let timerGroup = self.playStack.playGroup(layerType: property.layerType, playServiceId: play.playServiceId)
            log.debug("Start layer timer \(timerGroup)")
            timerGroup.forEach {
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
    
    func startTimer(property: PlaySyncProperty, duration: TimeIntervallic) {
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
            guard let play = self.playStack[property] else { return }
            
            log.debug("\(property) \(play.duration)")
            
            // Cancel timers
            self.removeTimer(property: property)

            // Start timers
            self.addTimer(property: property, duration: play.duration)
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
    public func contextInfoRequestContext(completion: (ContextInfo?) -> Void) {
        playSyncDispatchQueue.sync {
            log.debug("\(playStack.playServiceIds)")
            completion(ContextInfo(contextType: .client, name: "playStack", payload: playStack.playServiceIds))
        }
    }
}

// MARK: - Private

private extension PlaySyncManager {
    func pushToPlayStack(property: PlaySyncProperty, info: PlaySyncInfo) {
        // Cancel timers
        removeTimer(property: property)
        
        // Layer policy v.1.4.4. 2.2 Display 동작
        playStack
            // Multi-layer 상황에서 이전에 layer 와
            .previousPlayGroup(dialogRequestId: info.dialogRequestId)
            // 동일한 신규 layer 실행 시,
            .filter { $0.property.layerType == property.layerType }
            // 이전 layer 의 Display 는
            .filter { $0.property.contextType == .display }
            // playServiceId 가 다르거나 media layer 인 경우
            .filter { $0.play.playServiceId != info.playServiceId || property.layerType == .media }
            // 종료 시킨다.
            .forEach { popFromPlayStack(property: $0.property) }
        
        playStack[property] = info
    }
    
    func popFromPlayStack(property: PlaySyncProperty) {
        guard let play = playStack[property] else { return }
        
        // Cancel timers
        removeTimer(property: property)
        
        playStack[property] = nil
        
        delegates.notify { (delegate) in
            delegate.playSyncDidRelease(property: property, messageId: play.messageId)
        }
    }
    
    func addTimer(property: PlaySyncProperty, duration: TimeIntervallic) {
        guard duration.dispatchTimeInterval != .never else { return }
        
        let disposeBag = DisposeBag()
        Completable.create { [weak self] (event) -> Disposable in
            guard let self = self else { return Disposables.create() }

            log.debug("Timer fired. \(property) duration \(duration)")
            self.popFromPlayStack(property: property)
            
            event(.completed)
            return Disposables.create()
        }
        .delaySubscription(duration.dispatchTimeInterval, scheduler: playSyncScheduler)
        .subscribe()
        .disposed(by: disposeBag)
        
        playContextTimers[property] = disposeBag
    }
    
    func removeTimer(property: PlaySyncProperty) {
        playContextTimers[property] = nil
    }
}
