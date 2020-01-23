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

import NuguInterface

import RxSwift

public class PlaySyncManager: PlaySyncManageable {
    private let playSyncDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.play_sync", qos: .userInitiated)
    private lazy var playSyncScheduler = SerialDispatchQueueScheduler(
        queue: playSyncDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.play_sync"
    )
    
    private let disposeBag = DisposeBag()
    private var playSyncInfos = [PlaySyncInfo]()
    public var playServiceIds: [String] {
        return playSyncInfos.filter { $0.playSyncState != .released }
            .compactMap { $0.playServiceId }
            .reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
    }
    
    public init() {
        log.debug("")
    }
    
    deinit {
        log.debug("")
    }
}

// MARK: - PlaySyncManageable

public extension PlaySyncManager {
    func prepareSync(delegate: PlaySyncDelegate, dialogRequestId: String, playServiceId: String?) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.playSyncInfos.object(forDelegate: delegate, dialogRequestId: dialogRequestId)?.playSyncState != .prepared else {
                log.info("\(delegate): Already prepared")
                return
            }
            
            self.set(delegate: delegate, dialogRequestId: dialogRequestId, playServiceId: playServiceId, playSyncState: .prepared)
        }
    }
    
    func startSync(delegate: PlaySyncDelegate, dialogRequestId: String, playServiceId: String?) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.playSyncInfos.object(forDelegate: delegate, dialogRequestId: dialogRequestId)?.playSyncState != .synced else {
                log.info("\(delegate): Already synced")
                return
            }
            
            self.set(delegate: delegate, dialogRequestId: dialogRequestId, playServiceId: playServiceId, playSyncState: .synced)
        }
    }
    
    func cancelSync(delegate: PlaySyncDelegate, dialogRequestId: String, playServiceId: String?) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let info = self.playSyncInfos.object(forDelegate: delegate, dialogRequestId: dialogRequestId) else {
                log.warning("\(delegate): Layer not registered")
                return
            }
            self.playSyncInfos.remove(element: info)
        }
    }
    
    func releaseSync(delegate: PlaySyncDelegate, dialogRequestId: String, playServiceId: String?) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let info = self.playSyncInfos.object(forDelegate: delegate, dialogRequestId: dialogRequestId) else {
                log.warning("\(delegate): Layer not registered")
                return
            }
            guard info.playSyncState != .released else {
                log.info("\(delegate): Already released")
                return
            }
            
            let targetLayer = self.playSyncInfos.filter { $0.dialogRequestId == dialogRequestId }
            let hasPreparedTatgetLayer = targetLayer.contains { $0.playSyncState == .prepared }
            let isSingleLayer = self.playSyncInfos.filter { $0.playSyncState == .synced }.count == 1
            
            Observable.from(targetLayer)
                .filter { $0.playSyncState != .released }
                // prepared 상태인 layer 가 있는 경우 요청한 layer 만 release 한다.
                .filter { !hasPreparedTatgetLayer || $0.delegate === delegate }
                .flatMap({ [weak self] (info) -> Observable<PlaySyncInfo> in
                    guard let self = self else { return Observable.empty() }
                    let latency: DispatchTimeInterval
                    if info.playSyncState != .releasing && (info.isDisplay || isSingleLayer) {
                        latency = info.duration.time
                    } else {
                        latency = .milliseconds(0)
                    }
                    return Observable.just(info)
                        .do(onNext: { log.debug("\($0) will release after \(latency)") })
                        .delay(latency, scheduler: self.playSyncScheduler)
                })
                .do(onNext: {  [weak self] (info) in
                    guard let self = self else { return }
                    guard let target = info.delegate else { return }
                    if info.playSyncState == .releasing {
                        self.update(delegate: target, dialogRequestId: dialogRequestId, playServiceId: playServiceId, playSyncState: .released)
                    } else {
                        self.update(delegate: target, dialogRequestId: dialogRequestId, playServiceId: playServiceId, playSyncState: .releasing)
                    }
                })
                .subscribe().disposed(by: self.disposeBag)
        }
    }
    
    func releaseSyncImmediately(dialogRequestId: String, playServiceId: String?) {
        playSyncDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.playSyncInfos
                .filter { $0.dialogRequestId == dialogRequestId && $0.playSyncState != .released }
                .compactMap { $0.delegate }
                .forEach { self.update(delegate: $0, dialogRequestId: dialogRequestId, playServiceId: playServiceId, playSyncState: .released) }
        }
    }
}

// MARK: - ContextInfoDelegate
extension PlaySyncManager: ContextInfoDelegate {
    public func contextInfoRequestContext() -> ContextInfo? {
        return ContextInfo(contextType: .client, name: "playStack", payload: playServiceIds)
    }
}

// MARK: - Private

private extension PlaySyncManager {
    func set(delegate: PlaySyncDelegate, dialogRequestId: String, playServiceId: String?, playSyncState: PlaySyncState) {
        playSyncInfos.removeAll { $0.delegate === delegate }
        let playSyncInfo = PlaySyncInfo(
            delegate: delegate,
            dialogRequestId: dialogRequestId,
            playServiceId: playServiceId,
            playSyncState: playSyncState
        )
        playSyncInfos.insert(playSyncInfo, at: 0)
        
        delegate.playSyncDidChange(state: playSyncState, dialogRequestId: dialogRequestId)
        log.debug(playSyncInfos)
    }
    
    func update(delegate: PlaySyncDelegate, dialogRequestId: String, playServiceId: String?, playSyncState: PlaySyncState) {
        let playSyncInfo = PlaySyncInfo(
            delegate: delegate,
            dialogRequestId: dialogRequestId,
            playServiceId: playServiceId,
            playSyncState: playSyncState
        )
        guard playSyncInfos.replace(info: playSyncInfo) else {
            log.warning("\(delegate): Failed update to \(playSyncState).")
            return
        }
        
        delegate.playSyncDidChange(state: playSyncState, dialogRequestId: dialogRequestId)
        log.debug(playSyncInfos)
    }
}
