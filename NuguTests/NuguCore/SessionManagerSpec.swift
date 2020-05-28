//
//  SessionManagerSpec.swift
//  NuguTests
//
//  Created by MinChul Lee on 2020/05/28.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

import Quick
import Nimble

@testable import NuguCore

class SessionManagerSpec: QuickSpec {
    override func spec() {
        describe("SessionManager") {
            context("if it sync without session") {
                let sessionManager = SessionManager()
                sessionManager.sync(dialogRequestId: "1234")
            
                it("should has empty synced session") {
                    expect(sessionManager.syncedSessions.count).to(equal(0))
                }
            }
            context("if it session with sync") {
                let sessionManager = SessionManager()
                sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                sessionManager.sync(dialogRequestId: "1234")
                
                it("should has a synced session") {
                    expect(sessionManager.syncedSessions.count).to(equal(1))
                    
                }
            }

            context("if it syncing with session") {
                context("and release sync with this session") {
                    let sessionManager = SessionManager()
                    sessionManager.sync(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.release(dialogRequestId: "1234")
                    
                    it("should has empty synced session") {
                        expect(sessionManager.syncedSessions.count).to(equal(0))
                    }
                }
            }

            context("if it syncing with session") {
                context("and release multiple sync with this session") {
                    let sessionManager = SessionManager()
                    sessionManager.sync(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.release(dialogRequestId: "1234")
                    sessionManager.release(dialogRequestId: "1234")
                    
                    it("should has empty synced session") {
                        expect(sessionManager.syncedSessions.count).to(equal(0))
                    }
                }
            }

            context("if it syncing with session") {
                context("and release sync with another session") {
                    let sessionManager = SessionManager()
                    sessionManager.sync(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.release(dialogRequestId: "4567")
                    
                    it("should has a synced session") {
                        expect(sessionManager.syncedSessions.count).to(equal(1))
                    }
                }
            }
            
            context("if it sync with session") {
                let sessionManager = SessionManager()
                sessionManager.sync(dialogRequestId: "1234")
                sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                
                it("should has a synced session") {
                    expect(sessionManager.syncedSessions.count).to(equal(1))
                }
            }
            
            context("if it multiple sync with multiple session") {
                let sessionManager = SessionManager()
                sessionManager.sync(dialogRequestId: "1234")
                sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                sessionManager.sync(dialogRequestId: "4567")
                sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "4567", playServiceId: "aa"))
                
                it("should has multiple synced session") {
                    expect(sessionManager.syncedSessions.count).to(equal(2))
                }
            }
            
            context("if it multiple sync with multiple session") {
                context("and release sync session") {
                    let sessionManager = SessionManager()
                    sessionManager.sync(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.sync(dialogRequestId: "4567")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "4567", playServiceId: "aa"))
                    sessionManager.release(dialogRequestId: "4567")
                    
                    it("should has a synced session") {
                        expect(sessionManager.syncedSessions.count).to(equal(1))
                    }
                }
            }
            
            context("if it multiple sync with a session") {
                let sessionManager = SessionManager()
                sessionManager.sync(dialogRequestId: "1234")
                sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                sessionManager.sync(dialogRequestId: "1234")
                
                it("should has a synced session") {
                    expect(sessionManager.syncedSessions.count).to(equal(1))
                }
            }
            
            context("if it multiple sync with a session") {
                context("and release sync this session") {
                    let sessionManager = SessionManager()
                    sessionManager.sync(dialogRequestId: "1234")
                    sessionManager.sync(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.release(dialogRequestId: "1234")
                    
                    it("should has a synced session") {
                        expect(sessionManager.syncedSessions.count).to(equal(1))
                    }
                }
            }
            
            context("if it multiple sync with a session") {
                context("and multiple release sync this session") {
                    let sessionManager = SessionManager()
                    sessionManager.sync(dialogRequestId: "1234")
                    sessionManager.sync(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.release(dialogRequestId: "1234")
                    sessionManager.release(dialogRequestId: "1234")
                    
                    it("should has empty synced session") {
                        expect(sessionManager.syncedSessions.count).to(equal(0))
                    }
                }
            }
        }
    }
}
