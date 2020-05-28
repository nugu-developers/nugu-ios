//
//  SessionManager.swift
//  NuguCore
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

final public class SessionManager: SessionManageable {
    private let sessionDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.session", qos: .userInitiated)
    
    public init() {}
    
    public var syncedSessions: [Session] {
        sessionDispatchQueue.sync {
            return sessions
                .filter { $0.value.refCount > 0 }
                .compactMap { $0.value.session }
        }
    }
    public var sessions = [String: (session: Session?, refCount: Int)]()
    
    public func set(session: Session) {
        sessionDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            let oldSession = self.sessions[session.dialogRequestId]
            self.sessions[session.dialogRequestId] = (session: session, refCount: (oldSession?.refCount ?? 0))
        }
    }
    
    public func sync(dialogRequestId: String) {
        sessionDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            let session = self.sessions[dialogRequestId]
            self.sessions[dialogRequestId] = (session?.session, (session?.refCount ?? 0) + 1)
        }
    }
    
    public func release(dialogRequestId: String) {
        sessionDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let session = self.sessions[dialogRequestId] else { return }
            
            let refCount = max(session.refCount - 1, 0)
            
            if refCount == 0 {
                self.sessions[dialogRequestId] = nil
            } else {
                self.sessions[dialogRequestId] = (session.session, refCount)
            }
        }
    }
}
