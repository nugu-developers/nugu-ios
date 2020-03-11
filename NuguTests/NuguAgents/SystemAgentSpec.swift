//
//  SystemAgentSpec.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2019/11/28.
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

import Quick
import Nimble

@testable import NuguAgents
@testable import NuguCore

class SystemAgentSpec: QuickSpec {
    
    // NuguCore(Mock)
    let contextManager = MockContextManager()
    let networkManager = MockNetworkManager()
    let upstreamDataSender = MockStreamDataRouter()
    let directiveSequencer = MockDirectiveSequencer()
    
    override func spec() {
        describe("SystemAgent") {
            let systemAgent: SystemAgent = SystemAgent(
                contextManager: contextManager,
                networkManager: networkManager,
                upstreamDataSender: upstreamDataSender,
                directiveSequencer: directiveSequencer
            )
            
            describe("context") {
                var contextInfo: ContextInfo?
                
                waitUntil(timeout: 0.05) { (done) in
                    systemAgent.contextInfoRequestContext { (context) in
                        contextInfo = context
                        done()
                    }
                }
                
                it("is contextInfo") {
                    expect(contextInfo).toNot(beNil())
                }
                
                it("is contextName") {
                    expect(contextInfo?.name).to(equal(systemAgent.capabilityAgentProperty.name))
                }
                
                let payload = contextInfo?.payload as? [String: Any]
                
                it("is dictionary type") {
                    expect(payload).toNot(beNil())
                }
                
                it("is payload") {
                    expect(payload?["version"] as? String).to(equal(systemAgent.capabilityAgentProperty.version))
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
