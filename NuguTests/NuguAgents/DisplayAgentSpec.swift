//
//  DisplayAgentSpec.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2020/03/02.
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

import Quick
import Nimble

@testable import NuguAgents
@testable import NuguCore

class DisplayAgentSpec: QuickSpec {
    
    // NuguCore(Mock)
    let focusManager: FocusManageable = MockFocusManager()
    let upstreamDataSender: UpstreamDataSendable = MockStreamDataRouter()
    let playSyncManager: PlaySyncManageable = MockPlaySyncManager()
    let contextManager: ContextManageable = MockContextManager()
    let directiveSequencer: DirectiveSequenceable = MockDirectiveSequencer()
    let sessionManager: SessionManageable = MockSessionManager()
    let interactionControlManager: InteractionControlManageable = MockInteractionControlManager()
    
    override func spec() {
        describe("DisplayAgent") {
            let displayAgent: DisplayAgent = DisplayAgent(
                upstreamDataSender: upstreamDataSender,
                playSyncManager: playSyncManager,
                contextManager: contextManager,
                directiveSequencer: directiveSequencer,
                sessionManager: sessionManager,
                interactionControlManager: interactionControlManager
            )
            
            describe("context") {
                
                var contextInfo: ContextInfo?
                waitUntil(timeout: 0.5) { (done) in
                    displayAgent.contextInfoProvider { (context) in
                        contextInfo = context
                        done()
                    }
                }
                
                it("is contextInfo") {
                    expect(contextInfo).toNot(beNil())
                }
                
                it("is contextName") {
                    expect(contextInfo?.name).to(equal(displayAgent.capabilityAgentProperty.name))
                }
                
                let payload = contextInfo?.payload as? [String: Any]
                it("is dictionary type") {
                    expect(payload).toNot(beNil())
                }
                
                it("is payload") {
                    expect(payload?["version"] as? String).to(equal(displayAgent.capabilityAgentProperty.version))
                }
            }
            
            describe("directive") {
                // TODO: -
            }
            
            describe("event") {
                // TODO: -
            }
        }
    }
}
