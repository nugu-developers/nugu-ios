//
//  SoundAgentSpec.swift
//  NuguTests
//
//  Created by MinChul Lee on 2020/04/13.
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

class SoundAgentSpec: QuickSpec {
    // NuguCore(Mock)
    let focusManager: FocusManageable = MockFocusManager()
    let contextManager: ContextManageable = MockContextManager()
    let upstreamDataSender: UpstreamDataSendable = MockStreamDataRouter()
    let directiveSequencer: DirectiveSequenceable = DirectiveSequencer()
    
    private var state = [SoundState]()
    
    override func spec() {
        describe("SoundAgent") {
            let soundAgent: SoundAgent = SoundAgent(
                focusManager: focusManager,
                upstreamDataSender: upstreamDataSender,
                contextManager: contextManager,
                directiveSequencer: directiveSequencer
            )
            soundAgent.delegate = self
            soundAgent.dataSource = self
            
            describe("context") {
                var contextInfo: ContextInfo?
                
                waitUntil(timeout: 0.05) { (done) in
                    soundAgent.contextInfoRequestContext { (context) in
                        contextInfo = context
                        done()
                    }
                }
                
                it("is contextInfo") {
                    expect(contextInfo).toNot(beNil())
                }
                
                it("is contextName") {
                    expect(contextInfo?.name).to(equal(soundAgent.capabilityAgentProperty.name))
                }
                
                let payload = contextInfo?.payload as? [String: Any]
                
                it("is dictionary type") {
                    expect(payload).toNot(beNil())
                }
                
                it("is payload") {
                    expect(payload?["version"] as? String).to(equal(soundAgent.capabilityAgentProperty.version))
                }
            }
            
            describe("directive") {
                context("if it receives a beep directive") {
                    let header = Downstream.Header(
                        namespace: soundAgent.capabilityAgentProperty.name,
                        name: "Beep",
                        dialogRequestId: TimeUUID().hexString,
                        messageId: TimeUUID().hexString,
                        version: soundAgent.capabilityAgentProperty.version
                    )
                    let payload: [String: AnyHashable] = ["playServiceId": "nugu.system.fallback", "beepName": "RESPONSE_FAIL"]
                    if let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) {
                        let directive = Downstream.Directive(header: header, payload: payloadData)
                        directiveSequencer.processDirective(directive)
                    }
                    
                    it("should beep") {
                        expect(self.state).toEventually(contain(.playing), timeout: 3.0)
                        // TODO: Travis does not support playing `AVPlayerItem`.
                        // expect(self.state).toEventually(equal([.playing, .finished]), timeout: 3.0)
                    }
                }
            }
            
            describe("event") {
                // TODO: -
            }
        }
    }
}

// MARK: - SoundAgentDataSource

extension SoundAgentSpec: SoundAgentDataSource {
    func soundAgentRequestUrl(beepName: SoundBeepName) -> URL? {
        return Bundle(for: type(of: self)).url(forResource: "asrFail", withExtension: "wav")
    }
}

// MARK: - SoundAgentDelegate

extension SoundAgentSpec: SoundAgentDelegate {
    func soundAgentDidChange(state: SoundState, dialogRequestId: String) {
        self.state.append(state)
    }
}
