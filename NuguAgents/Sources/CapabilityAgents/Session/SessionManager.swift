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
import NuguUtils

import RxSwift

final public class SessionManager: SessionManageable {
    private let sessionDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.session", qos: .userInitiated)
    private lazy var sessionScheduler = SerialDispatchQueueScheduler(
        queue: sessionDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.session"
    )
    
    /// Active sessions sorted chronologically.
    public var activeSessions = [Session]() {
        didSet {
            if oldValue != activeSessions {
                log.debug(activeSessions)
            }
        }
    }
    
    // private
    private let notificationCenter = NotificationCenter.default
    private var activeTimers = [String: Disposable]()
    private var sessions = [String: Session]() {
        didSet {
            updateActiveSession()
        }
    }

    private var activeList = [String: Set<CapabilityAgentCategory>]() {
        didSet {
            updateActiveSession()
        }
    }
    
    public init() {}
    
    public func set(session: Session) {
        sessionDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            log.debug(session.dialogRequestId)
            self.sessions[session.dialogRequestId] = session
            self.addTimer(session: session)
            
            self.addActiveSession(dialogRequestId: session.dialogRequestId)
            self.notificationCenter.post(name: .sessionDidSet, object: self, userInfo: [ObservingFactor.Set.session: session])
        }
    }
    
    public func activate(dialogRequestId: String, category: CapabilityAgentCategory) {
        sessionDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            log.debug(dialogRequestId)
            self.removeTimer(dialogRequestId: dialogRequestId)
            
            if self.activeList[dialogRequestId] == nil {
                self.activeList[dialogRequestId] = []
            }
            self.activeList[dialogRequestId]?.insert(category)
            self.addActiveSession(dialogRequestId: dialogRequestId)
        }
    }
    
    public func deactivate(dialogRequestId: String, category: CapabilityAgentCategory) {
        sessionDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            log.debug(dialogRequestId)
            self.activeList[dialogRequestId]?.remove(category)
            if self.activeList[dialogRequestId]?.count == 0 {
                self.activeList[dialogRequestId] = nil
                
                if let session = self.sessions[dialogRequestId] {
                    self.addTimer(session: session)
                }
            }
        }
    }
}

private extension SessionManager {
    func addTimer(session: Session) {
        activeTimers[session.dialogRequestId] = Single<Int>.timer(SessionConst.sessionTimeout, scheduler: sessionScheduler)
            .subscribe(onSuccess: { [weak self] _ in
                log.debug("Timer fired. \(session.dialogRequestId)")
                self?.sessions[session.dialogRequestId] = nil
                self?.notificationCenter.post(name: .sessionDidUnSet, object: self, userInfo: [ObservingFactor.Set.session: session])
            })
    }
    
    func removeTimer(dialogRequestId: String) {
        activeTimers[dialogRequestId]?.dispose()
        activeTimers[dialogRequestId] = nil
    }
    
    func addActiveSession(dialogRequestId: String) {
        guard let session = sessions[dialogRequestId], activeList[dialogRequestId] != nil else { return }
        
        activeSessions.removeAll { $0.dialogRequestId == dialogRequestId }
        activeSessions.append(session)
    }
    
    func updateActiveSession() {
        activeSessions.removeAll { (session) -> Bool in
            sessions[session.dialogRequestId] == nil || activeList[session.dialogRequestId] == nil
        }
    }
}

// MARK: - Observers

// TODO: 세션 set/unset을 해당 session을 생성하지 않은 다른 곳에서 알 필요가 있는지? (session delegate는 session이 들고있어야 마땅한데, session manager가 여러 session delegate를 들고있으면서 모두에게 전달한 상황)
extension Notification.Name {
    static let sessionDidSet = Notification.Name("com.sktelecom.romaine.notification.name.session_did_set")
    static let sessionDidUnSet = Notification.Name("com.sktelecom.romaine.notification.name.session_did_unset")
}

extension SessionManager: Observing {
    public enum ObservingFactor {
        public enum Set: ObservingSpec {
            case session
            
            public var name: Notification.Name {
                .sessionDidSet
            }
        }
        
        public enum Unset: ObservingSpec {
            case session
            
            public var name: Notification.Name {
                .sessionDidUnSet
            }
        }
    }
}
