//
//  ExtensionAgentSpec.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2020/02/17.
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

class ExtensionAgentSpec: QuickSpec {
    
    // NuguCore(Mock)
    let contextManager: ContextManageable = MockContextManager()
    let upstreamDataSender: UpstreamDataSendable = MockStreamDataRouter()
    let directiveSequencer: DirectiveSequenceable = MockDirectiveSequencer()
    
    override func spec() {
        describe("ExtensionAgent") {
            let extensionAgent: ExtensionAgent = ExtensionAgent(
                upstreamDataSender: upstreamDataSender,
                contextManager: contextManager,
                directiveSequencer: directiveSequencer
            )
            let mockExtensionAgentDelegate: ExtensionAgentDelegate = MockExtensionAgentDelegate()
            
            extensionAgent.delegate = mockExtensionAgentDelegate // CHECK-ME: Replace a better way
            
            describe("context") {
                var contextInfo: ContextInfo?
                
                waitUntil(timeout: .milliseconds(500)) { (done) in
                    extensionAgent.contextInfoProvider { (context) in
                        contextInfo = context
                        done()
                    }
                }
                
                it("is contextInfo") {
                    expect(contextInfo).toNot(beNil())
                }
                
                it("is contextName") {
                    expect(contextInfo?.name).to(equal(extensionAgent.capabilityAgentProperty.name))
                }
                
                let payload = contextInfo?.payload as? [String: Any]
                
                it("is dictionary type") {
                    expect(payload).toNot(beNil())
                }
                
                it("is payload") {
                    expect(payload?["version"] as? String).to(equal(extensionAgent.capabilityAgentProperty.version))
                    
                    let data = payload?["data"] as? [String: Any]
                    expect(data?["test"] as? String).to(equal("context"))
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

// MARK: - MockExtensionAgentDelegate

class MockExtensionAgentDelegate: ExtensionAgentDelegate {
    func extensionAgentRequestContext() -> [String: AnyHashable]? {
        return [
            "test": "context"
        ]
    }
    
    func extensionAgentDidReceiveAction(data: [String : AnyHashable], playServiceId: String, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}
