//
//  TextAgentSpec.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2020/02/18.
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

class TextAgentSpec: QuickSpec {
    
    // NuguCore(Mock)
    let focusManager: FocusManageable = MockFocusManager()
    let contextManager: ContextManageable = MockContextManager()
    let upstreamDataSender: UpstreamDataSendable = MockStreamDataRouter()
    let directiveSequencer: DirectiveSequenceable = MockDirectiveSequencer()
    let dialogAttributeStore: DialogAttributeStoreable = MockDialogAttributeStore()
    let interactionControlManager: InteractionControlManageable = MockInteractionControlManager()
    
    override func spec() {
        describe("TextAgent") {
            let textAgent: TextAgent = TextAgent(
                contextManager: contextManager,
                upstreamDataSender: upstreamDataSender,
                directiveSequencer: directiveSequencer,
                dialogAttributeStore: dialogAttributeStore,
                interactionControlManager: interactionControlManager
            )
            let mockTextAgentDelegate = MockTextAgentDelegate()
            textAgent.delegate = mockTextAgentDelegate
            
            describe("context") {
                var contextInfo: ContextInfo?
                
                waitUntil(timeout: .milliseconds(500)) { (done) in
                    textAgent.contextInfoProvider { (context) in
                        contextInfo = context
                        done()
                    }
                }
                
                it("is contextInfo") {
                    expect(contextInfo).toNot(beNil())
                }
                
                it("is contextName") {
                    expect(contextInfo?.name).to(equal(textAgent.capabilityAgentProperty.name))
                }
                
                let payload = contextInfo?.payload as? [String: Any]
                
                it("is dictionary type") {
                    expect(payload).toNot(beNil())
                }
                
                it("is payload") {
                    expect(payload?["version"] as? String).to(equal(textAgent.capabilityAgentProperty.version))
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

// MARK: - TextAgentDelegate

class MockTextAgentDelegate: TextAgentDelegate {
    func textAgentShouldHandleTextSource(directive: Downstream.Directive) -> Bool {
        return true
    }
    
    func textAgentShouldHandleTextRedirect(directive: Downstream.Directive) -> Bool {
        return true
    }
    
    func textAgentShouldTyping(directive: Downstream.Directive) -> Bool {
        return true
    }
}
