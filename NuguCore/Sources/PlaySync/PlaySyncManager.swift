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
    private var playContextTimers = [PlaySyncProperty: Disposable]()
    private var timerPaused = false
    private var pausedTimers = Set<PlaySyncProperty>()
    
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
            let timerGroup = self.playStack
                .filter { $0.property.layerType == property.layerType && $0.info.playStackServiceId == info.playStackServiceId }
                .map { $0.property }
            log.debug("Cancel layer timer \(timerGroup)")
            timerGroup.forEach(self.removeTimer)
            
            // Start display only timer
            let directiveGroup = self.playStack.filter { $0.info.dialogRequestId == info.dialogRequestId }
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
            let timerGroup = self.playStack
                .filter { $0.property.layerType == property.layerType && $0.info.playStackServiceId == play.playStackServiceId }
                .map { $0.property }
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
            self.playStack
                .filter { $0.info.dialogRequestId == dialogRequestId }
                .map { $0.property }
                .forEach(self.popFromPlayStack)
        }
    }
    
    func startTimer(property: PlaySyncProperty, duration: TimeIntervallic) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.playStack[property] != nil else { return }
            
            log.debug("\(property) \(duration)")
            
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
            self.playContextTimers[property]?.dispose()
        }
    }
    
    func pauseTimer(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            log.debug(property)
            self.timerPaused = true
            
            if self.playContextTimers[property] != nil {
                self.pausedTimers.insert(property)
                self.removeTimer(property: property)
            }
        }
    }
    
    func resumeTimer(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            log.debug(property)
            self.timerPaused = false

            self.pausedTimers.forEach { property in
                guard let play = self.playStack[property] else { return }
                self.addTimer(property: property, duration: play.duration)
            }
            self.pausedTimers.removeAll()
        }
    }
}

// MARK: - ContextInfoDelegate
extension PlaySyncManager: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: @escaping (ContextInfo?) -> Void) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            log.debug("\(self.playStack.playServiceIds)")
            completion(ContextInfo(contextType: .client, name: "playStack", payload: self.playStack.playServiceIds))
        }
    }
}

// MARK: - Private

private extension PlaySyncManager {
    func pushToPlayStack(property: PlaySyncProperty, info: PlaySyncInfo) {
        // Cancel timers
        removeTimer(property: property)
        
        // Layer policy v.1.4.8. 2.2 Display 동작. Multi-layer 상황 Display 표출정책
        playStack
            // Multi-layer 상황에서
            .filter { $0.info.dialogRequestId != info.dialogRequestId }
            // 이전 layer 가 info 나 alerts 이면
            .filter { $0.property.layerType == .info || $0.property.layerType == .alert }
            // 해당 layer의 display 표출 중
            .filter { $0.property.contextType == .display }
            // 다른 display 또는 다른 play 동작 시
            .filter { property.contextType == .display || $0.info.playStackServiceId != info.playStackServiceId }
            // 이전 display 를 종료함
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
        log.debug(property)
        removeTimer(property: property)
        
        guard duration.dispatchTimeInterval != .never else { return }
        guard timerPaused == false else {
            pausedTimers.insert(property)
            return
        }
        
        playContextTimers[property] = Single<Int>.timer(duration.dispatchTimeInterval, scheduler: playSyncScheduler)
            .subscribe(onSuccess: { [weak self] _ in
                log.debug("Timer fired. \(property) duration \(duration)")
                self?.popFromPlayStack(property: property)
            })
    }
    
    func removeTimer(property: PlaySyncProperty) {
        log.debug(property)
        playContextTimers[property]?.dispose()
        playContextTimers[property] = nil
        pausedTimers.remove(property)
    }
}
