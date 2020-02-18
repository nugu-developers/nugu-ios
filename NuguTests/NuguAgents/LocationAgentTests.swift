//
//  LocationAgentTests.swift
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

import XCTest

@testable import NuguAgents
@testable import NuguCore

class LocationAgentTests: XCTestCase {
    
    // NuguCore(Mock)
    let contextManager: ContextManageable = MockContextManager()
    
    // NuguAgents
    lazy var locationAgent: LocationAgent = LocationAgent(contextManager: contextManager)
    
    // Override
    override func setUp() {
        locationAgent.delegate = self
    }
    
    override func tearDown() {
        locationAgent.delegate = nil
    }
    
    // MARK: Context
    
    func testContext() {
        /* Expected context
        {
            "Location": {
                "version": "1.0",
                "current": {
                    "latitude": "{{STRING}}",
                    "longitude": "{{STRING}}"
                }
            }
        }
        */
        locationAgent.contextInfoRequestContext { [weak self] contextInfo in
            guard let self = self else {
                XCTFail("self is nil")
                return
            }
            
            guard let contextInfo = contextInfo else {
                XCTFail("contextInfo is nil")
                return
            }
            
            XCTAssertEqual(contextInfo.name, self.locationAgent.capabilityAgentProperty.name)
            
            guard let payload = contextInfo.payload as? [String: Any] else {
                XCTFail("payload is nil or not dictionary")
                return
            }
            
            XCTAssertEqual(payload["version"] as? String, self.locationAgent.capabilityAgentProperty.version)
            
            guard let current = payload["current"] as? [String: Any] else {
                XCTFail("payload[\"current\"] is nil or not dictionary")
                return
            }
            
            XCTAssertEqual(current["latitude"] as? String, "10.1")
            XCTAssertEqual(current["longitude"] as? String, "20.9")
        }
    }
}

// MARK: - LocationAgentDelegate

extension LocationAgentTests: LocationAgentDelegate {
    func locationAgentRequestLocationInfo() -> LocationInfo? {
        return LocationInfo(latitude: String(10.1), longitude: String(20.9))
    }
}
