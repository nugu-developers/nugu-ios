//
//  LocationAgentSpec.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2020/02/10.
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

class LocationAgentSpec: QuickSpec {
    
    // NuguCore(Mock)
    let contextManager: ContextManageable = MockContextManager()
    
    override func spec() {
        describe("LocationAgent") {
            let locationAgent: LocationAgent = LocationAgent(contextManager: contextManager)
            let mockLocationAgentDelegate = MockLocationAgentDelegate()
            
            locationAgent.delegate = mockLocationAgentDelegate // CHECK-ME: Replace a better way
            
            describe("context") {
                var contextInfo: ContextInfo?
                
                waitUntil(timeout: 0.5) { (done) in
                    locationAgent.contextInfoRequestContext { (context) in
                        contextInfo = context
                        done()
                    }
                }
                
                it("is contextInfo") {
                    expect(contextInfo).toNot(beNil())
                }
                
                it("is contextName") {
                    expect(contextInfo?.name).to(equal(locationAgent.capabilityAgentProperty.name))
                }
                
                let payload = contextInfo?.payload as? [String: Any]
                
                it("is dictionary type") {
                    expect(payload).toNot(beNil())
                }
                
                it("is payload") {
                    expect(payload?["version"] as? String).to(equal(locationAgent.capabilityAgentProperty.version))

                    let current = payload?["current"] as? [String: Any]
                    expect(current?["latitude"] as? String).to(equal("10.1"))
                    expect(current?["longitude"] as? String).to(equal("20.9"))
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

// MARK: - MockLocationAgentDelegate

class MockLocationAgentDelegate: LocationAgentDelegate {
    func locationAgentRequestLocationInfo() -> LocationInfo? {
        return LocationInfo(latitude: String(10.1), longitude: String(20.9))
    }
}
