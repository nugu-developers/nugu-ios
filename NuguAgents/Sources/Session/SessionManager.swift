//
//  SessionManager.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/05/28.
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

import NuguCore

import RxSwift

final public class SessionManager: SessionManageable {
    private let sessionDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.session", qos: .userInitiated)
    private lazy var sessionScheduler = SerialDispatchQueueScheduler(
        queue: sessionDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.session"
    )
    
    public var activeSessions: [Session] {
        sessionDispatchQueue.sync {
            return activeList
                .filter { $0.value.count > 0 }
                .compactMap { sessions[$0.key] }
        }
    }
    
    // private
    private let delegates = DelegateSet<SessionDelegate>()
    private var activeTimers = [String: DisposeBag]()
    private var sessions = [String: Session]()
    private var activeList = [String: Set<CapabilityAgentCategory>]()
    
    public init() {}
    
    public func add(delegate: SessionDelegate) {
        delegates.add(delegate)
    }
    
    public func remove(delegate: SessionDelegate) {
        delegates.remove(delegate)
    }
    
    public func set(session: Session) {
        sessionDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.sessions[session.dialogRequestId] = session
            self.addTimer(dialogRequestId: session.dialogRequestId)
        }
    }
    
    public func activate(dialogRequestId: String, category: CapabilityAgentCategory) {
        sessionDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.removeTimer(dialogRequestId: dialogRequestId)
            
            if self.activeList[dialogRequestId] == nil {
                self.activeList[dialogRequestId] = []
            }
            self.activeList[dialogRequestId]?.insert(category)
            
            if let session = self.sessions[dialogRequestId] {
                self.delegates.notify { (delegate) in
                    delegate.sessionDidActivate(session: session)
                }
            }
        }
    }
    
    public func deactivate(dialogRequestId: String, category: CapabilityAgentCategory) {
        sessionDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.activeList[dialogRequestId]?.remove(category)
            if self.activeList[dialogRequestId]?.count == 0 {
                self.removeSession(dialogRequestId: dialogRequestId)
            }
        }
    }
}

private extension SessionManager {
    func removeSession(dialogRequestId: String) {
        activeList[dialogRequestId] = nil
        if let session = sessions[dialogRequestId] {
            sessions[dialogRequestId] = nil
            delegates.notify { (delegate) in
                delegate.sessionDidDeactivate(session: session)
            }
        }
    }
    
    func addTimer(dialogRequestId: String) {
        let disposeBag = DisposeBag()
        Completable.create { [weak self] (event) -> Disposable in
            guard let self = self else { return Disposables.create() }

            log.debug("Timer fired. \(dialogRequestId)")
            self.removeSession(dialogRequestId: dialogRequestId)
            
            event(.completed)
            return Disposables.create()
        }
        .delaySubscription(SessionConst.sessionTimeout, scheduler: sessionScheduler)
        .subscribe()
        .disposed(by: disposeBag)
        
        activeTimers[dialogRequestId] = disposeBag
    }
    
    func removeTimer(dialogRequestId: String) {
        activeTimers[dialogRequestId] = nil
    }
}
