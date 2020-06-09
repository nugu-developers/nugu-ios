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
            context("if it activate without session") {
                let sessionManager = SessionManager()
                sessionManager.activate(dialogRequestId: "1234")
            
                it("should has empty synced session") {
                    expect(sessionManager.activeSessions.count).to(equal(0))
                }
            }
            context("if it activate with session") {
                let sessionManager = SessionManager()
                sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                sessionManager.activate(dialogRequestId: "1234")
                
                it("should has a synced session") {
                    expect(sessionManager.activeSessions.count).to(equal(1))
                    
                }
            }

            context("if it activate with session") {
                context("and deactivate with this session") {
                    let sessionManager = SessionManager()
                    sessionManager.activate(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.deactivate(dialogRequestId: "1234")
                    
                    it("should has empty synced session") {
                        expect(sessionManager.activeSessions.count).to(equal(0))
                    }
                }
            }

            context("if it activate with session") {
                context("and deactivate multiple with this session") {
                    let sessionManager = SessionManager()
                    sessionManager.activate(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.deactivate(dialogRequestId: "1234")
                    sessionManager.deactivate(dialogRequestId: "1234")
                    
                    it("should has empty active session") {
                        expect(sessionManager.activeSessions.count).to(equal(0))
                    }
                }
            }

            context("if it activate with session") {
                context("and deactivate with another session") {
                    let sessionManager = SessionManager()
                    sessionManager.activate(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.deactivate(dialogRequestId: "4567")
                    
                    it("should has a active session") {
                        expect(sessionManager.activeSessions.count).to(equal(1))
                    }
                }
            }
            
            context("if it activate with session") {
                let sessionManager = SessionManager()
                sessionManager.activate(dialogRequestId: "1234")
                sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                
                it("should has a active session") {
                    expect(sessionManager.activeSessions.count).to(equal(1))
                }
            }
            
            context("if it activate multiple with multiple session") {
                let sessionManager = SessionManager()
                sessionManager.activate(dialogRequestId: "1234")
                sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                sessionManager.activate(dialogRequestId: "4567")
                sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "4567", playServiceId: "aa"))
                
                it("should has multiple active session") {
                    expect(sessionManager.activeSessions.count).to(equal(2))
                }
            }
            
            context("if it multiple activate with multiple session") {
                context("and deactivate a session") {
                    let sessionManager = SessionManager()
                    sessionManager.activate(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.activate(dialogRequestId: "4567")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "4567", playServiceId: "aa"))
                    sessionManager.deactivate(dialogRequestId: "4567")
                    
                    it("should has a active session") {
                        expect(sessionManager.activeSessions.count).to(equal(1))
                    }
                }
            }
            
            context("if it activate multiple with a session") {
                let sessionManager = SessionManager()
                sessionManager.activate(dialogRequestId: "1234")
                sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                sessionManager.activate(dialogRequestId: "1234")
                
                it("should has a active session") {
                    expect(sessionManager.activeSessions.count).to(equal(1))
                }
            }
            
            context("if it activate multiple with a session") {
                context("and deactivate this session") {
                    let sessionManager = SessionManager()
                    sessionManager.activate(dialogRequestId: "1234")
                    sessionManager.activate(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.deactivate(dialogRequestId: "1234")
                    
                    it("should has a active session") {
                        expect(sessionManager.activeSessions.count).to(equal(1))
                    }
                }
            }
            
            context("if it activate multiple with a session") {
                context("and deactivate multiple with this session") {
                    let sessionManager = SessionManager()
                    sessionManager.activate(dialogRequestId: "1234")
                    sessionManager.activate(dialogRequestId: "1234")
                    sessionManager.set(session: Session(sessionId: "abc", dialogRequestId: "1234", playServiceId: "aa"))
                    sessionManager.deactivate(dialogRequestId: "1234")
                    sessionManager.deactivate(dialogRequestId: "1234")
                    
                    it("should has empty active session") {
                        expect(sessionManager.activeSessions.count).to(equal(0))
                    }
                }
            }
        }
    }
}
