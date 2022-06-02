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

import NuguUtils

import RxSwift

public class PlaySyncManager: PlaySyncManageable {
    private let playSyncDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.play_sync", qos: .userInitiated)
    private lazy var playSyncScheduler = SerialDispatchQueueScheduler(
        queue: playSyncDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.play_sync"
    )
    
    private let contextManager: ContextManageable
    
    private var playStack = PlayStack() {
        didSet {
            let properties = playStack.filter { $0.property.contextType == .display || playContextTimers[$0.property] == nil }
            post(NuguCoreNotification.PlaySync.SynchronizedProperties(properties: properties))
        }
    }
    private var playContextTimers = [PlaySyncProperty: Disposable]() {
        didSet {
            log.debug(playContextTimers.keys.map { (property) -> String in
                "\(property) \(timerDuration[property]?.seconds ?? 0)"
            })
        }
    }
    private var timerPaused = false
    private var pausedTimers = Set<PlaySyncProperty>()
    private var timerDuration = [PlaySyncProperty: TimeIntervallic]()
    
    public init(contextManager: ContextManageable) {
        self.contextManager = contextManager
        contextManager.addProvider(contextInfoProvider)
    }
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        self?.playSyncDispatchQueue.async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            log.debug("\(self.playStack.playServiceIds)")
            completion(ContextInfo(contextType: .client, name: "playStack", payload: self.playStack.playServiceIds))
        }
    }
}

// MARK: - PlaySyncManageable

public extension PlaySyncManager {
    func startPlay(property: PlaySyncProperty, info: PlaySyncInfo) {
        playSyncDispatchQueue.async { [weak self] in
            log.debug("\(property) \(info)")
            guard let self = self else { return }

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
            log.debug("\(property)")
            guard let self = self else { return }
            guard let play = self.playStack[property] else { return }
            
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
    
    func stopPlay(dialogRequestId: String, property: PlaySyncProperty? = nil) {
        playSyncDispatchQueue.async { [weak self] in
            log.debug(dialogRequestId)
            guard let self = self else { return }
            
            // Pop from play stack
            self.playStack
                .filter { $0.info.dialogRequestId == dialogRequestId }
                .filter { $0.property == property ?? $0.property }
                .map { $0.property }
                .forEach(self.popFromPlayStack)
        }
    }
    
    func startTimer(property: PlaySyncProperty, duration: TimeIntervallic) {
        playSyncDispatchQueue.async { [weak self] in
            log.debug(property)
            guard let self = self else { return }
            guard self.playStack[property] != nil else { return }
            
            // Start timers
            self.addTimer(property: property, duration: duration)
        }
    }
    
    func resetTimer(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            log.debug(property)
            guard let self = self else { return }
            guard self.playContextTimers[property] != nil else { return }
            guard let play = self.playStack[property] else { return }
                        
            // Start timers
            self.addTimer(property: property, duration: play.duration)
        }
    }
    
    func cancelTimer(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            log.debug(property)
            self?.removeTimer(property: property)
        }
    }
    
    func pauseTimer(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            log.debug(property)
            guard let self = self else { return }
            
            self.timerPaused = true
            
            if self.playContextTimers[property] != nil {
                self.removeTimer(property: property)
                self.pausedTimers.insert(property)
            }
        }
    }
    
    func resumeTimer(property: PlaySyncProperty) {
        playSyncDispatchQueue.async { [weak self] in
            log.debug(property)
            guard let self = self else { return }
            
            self.timerPaused = false

            self.pausedTimers.forEach { property in
                guard let duration = self.timerDuration[property] else { return }
                self.addTimer(property: property, duration: duration)
            }
            self.pausedTimers.removeAll()
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
            .filter { [.info, .alert].contains($0.property.layerType) }
            // 해당 layer의 display 표출 중
            .filter { $0.property.contextType == .display }
            // 다른 display 또는 다른 play 동작 시
            .filter { property.contextType == .display || $0.info.playStackServiceId != info.playStackServiceId }
            // history control 가 이전 display 는 parent, 새로운 display 는 child 가 아닐 시
            .filter { (($0.info.historyControl?["parent"]) as? Bool) != true && (info.historyControl?["child"] as? Bool) != true }
            // 이전 display 를 종료함
            .forEach { popFromPlayStack(property: $0.property) }
        playStack
            // Multi-layer 상황에서
            .filter { $0.info.dialogRequestId != info.dialogRequestId }
            // 이전 layer 가 media 나 call 이면
            .filter { [.media, .call].contains($0.property.layerType) }
            // 해당 layer의 display 표출 중
            .filter { $0.property.contextType == .display }
            // 같은 layer 실행 시
            .filter { $0.property.layerType == property.layerType }
            // 이전 display 를 종료함
            .forEach { popFromPlayStack(property: $0.property) }
        
        playStack[property] = info
    }
    
    func popFromPlayStack(property: PlaySyncProperty) {
        guard let play = playStack[property] else { return }
        
        // Cancel timers
        removeTimer(property: property)
        
        playStack[property] = nil
        
        post(NuguCoreNotification.PlaySync.ReleasedProperty(property: property, messageId: play.messageId))
    }
    
    func addTimer(property: PlaySyncProperty, duration: TimeIntervallic) {
        timerDuration[property] = duration
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
        guard playContextTimers[property] != nil || pausedTimers.contains(property) else { return }
        
        playContextTimers[property]?.dispose()
        playContextTimers[property] = nil
        pausedTimers.remove(property)
    }
}

// MARK: - Observer

extension Notification.Name {
    static let playSyncPropertyDidRelease = Notification.Name("com.sktelecom.romaine.notification.name.play_sync_property_did_release")
    static let playSyncPropertiesDidChange = Notification.Name("com.sktelecom.romaine.notification.name.play_sync_properties_did_change")
}

public extension NuguCoreNotification {
    enum PlaySync {
        public struct ReleasedProperty: TypedNotification {
            public static var name: Notification.Name = .playSyncPropertyDidRelease
            public let property: PlaySyncProperty
            public let messageId: String
            
            public static func make(from: [String: Any]) -> ReleasedProperty? {
                guard let property = from["property"] as? PlaySyncProperty,
                      let messageId = from["messageId"] as? String else { return nil }
                
                return ReleasedProperty(property: property, messageId: messageId)
            }
        }
        
        /// Notify the synchronized properties except for the sound layer where the timer is running.
        public struct SynchronizedProperties: TypedNotification {
            public static var name: Notification.Name = .playSyncPropertiesDidChange
            public let properties: [(property: PlaySyncProperty, info: PlaySyncInfo)]
            
            public static func make(from: [String: Any]) -> SynchronizedProperties? {
                guard let properties = from["properties"] as? [(property: PlaySyncProperty, info: PlaySyncInfo)] else { return nil }
                
                return SynchronizedProperties(properties: properties)
            }
        }
    }
}
