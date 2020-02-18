//
//  SystemAgentTests.swift
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


import XCTest

@testable import NuguAgents
@testable import NuguCore

class SystemAgentTests: XCTestCase {
    
    // NuguCore(Mock)
    let contextManager = MockContextManager()
    let networkManager = MockNetworkManager()
    let upstreamDataSender = MockStreamDataRouter()
    let directiveSequencer = MockDirectiveSequencer()
    
    // NuguAgents
    lazy var systemAgent: SystemAgent = SystemAgent(
        contextManager: contextManager,
        networkManager: networkManager,
        upstreamDataSender: upstreamDataSender,
        directiveSequencer: directiveSequencer
    )
    
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }

    // MARK: Context
    
    func testContext() {
        /* Expected context
         {
            "version": "1.0",
         }
         */
        systemAgent.contextInfoRequestContext(completionHandler: { [weak self] contextInfo in
            guard let self = self, let contextInfo = contextInfo else {
                XCTFail("contextInfo is nil")
                return
            }
            
            XCTAssertEqual(contextInfo.name, self.systemAgent.capabilityAgentProperty.name)
            
            guard let payload = contextInfo.payload as? [String: Any] else {
                XCTFail("context payload is nil or not dictionary")
                return
            }
            
            XCTAssertEqual(payload["version"] as? String, self.systemAgent.capabilityAgentProperty.version)
        })
    }
    
    // MARK: Directives
    
    func testHandoffConnectionDirective() {
        let rawData =
        """
        {
          "header": {
            "namespace": "System",
            "name": "HandoffConnection",
            "messageId": "0",
            "dialogRequestId": "0",
            "version": "1.0"
          },
          "payload": {
            "protocol": "H2",
            "hostname": "gw.sktnugu.com",
            "address": "211.188.153.175",
            "port": 443,
            "retryCountLimit": 10,
            "connectionTimeout": 5000,
            "charge": "Normal"
          }
        }
        """.data(using: .utf8)!
        
        testHandleDirective(rawData: rawData)
    }
    
    func testUpdateStateDirective() {
        let rawData =
        """
        {
          "header": {
            "namespace": "System",
            "name": "UpdateState",
            "messageId": "0",
            "dialogRequestId": "0",
            "version": "1.0"
          },
          "payload": {}
        }
        """.data(using: .utf8)!
        
        testHandleDirective(rawData: rawData)
    }
    
    // TODO: - Need to add failure case, validate exception-code
    func testExceptionDirective() {
        // UNAUTHORIZED_REQUEST_EXCEPTION
        let unauthorizedRequestExpectation = XCTestExpectation(description: "UNAUTHORIZED_REQUEST_EXCEPTION")
        let unauthorizedRequestDelegate = MockSystemAgentDelegate(code: .unauthorizedRequestException, expectation: unauthorizedRequestExpectation)
        systemAgent.add(systemAgentDelegate: unauthorizedRequestDelegate)

        let unauthorizedRequestRawData =
        """
        {
          "header": {
            "namespace": "System",
            "name": "Exception",
            "messageId": "0",
            "dialogRequestId": "0",
            "version": "1.0"
          },
          "payload": {
            "code": "UNAUTHORIZED_REQUEST_EXCEPTION",
            "description": "{{STRING}}"
          }
        }
        """.data(using: .utf8)!
        
        testHandleDirective(rawData: unauthorizedRequestRawData)
        wait(for: [unauthorizedRequestExpectation], timeout: 1.0)
        systemAgent.remove(systemAgentDelegate: unauthorizedRequestDelegate)
        
        // ASR_RECOGNIZING_EXCEPTION
        let asrRecognizingRawData =
        """
        {
          "header": {
            "namespace": "System",
            "name": "Exception",
            "messageId": "0",
            "dialogRequestId": "0",
            "version": "1.0"
          },
          "payload": {
            "code": "ASR_RECOGNIZING_EXCEPTION",
            "description": "{{STRING}}"
          }
        }
        """.data(using: .utf8)!

        testHandleDirective(rawData: asrRecognizingRawData)
        
        // PLAY_ROUTER_PROCESSING_EXCEPTION
        let playRouterProcessingExpectation = XCTestExpectation(description: "PLAY_ROUTER_PROCESSING_EXCEPTION")
        let playRouterProcessingDelegate = MockSystemAgentDelegate(code: .playRouterProcessingException, expectation: playRouterProcessingExpectation)
        systemAgent.add(systemAgentDelegate: playRouterProcessingDelegate)
        
        let playRouterProcessingRawData =
        """
        {
          "header": {
            "namespace": "System",
            "name": "Exception",
            "messageId": "0",
            "dialogRequestId": "0",
            "version": "1.0"
          },
          "payload": {
            "code": "PLAY_ROUTER_PROCESSING_EXCEPTION",
            "description": "{{STRING}}"
          }
        }
        """.data(using: .utf8)!

        testHandleDirective(rawData: playRouterProcessingRawData)
        wait(for: [playRouterProcessingExpectation], timeout: 1.0)
        systemAgent.remove(systemAgentDelegate: playRouterProcessingDelegate)
        
        // TTS_SPEAKING_EXCEPTION
        let ttsSpeakingExpectation = XCTestExpectation(description: "TTS_SPEAKING_EXCEPTION")
        let ttsSpeakingDelegate = MockSystemAgentDelegate(code: .ttsSpeakingException, expectation: ttsSpeakingExpectation)
        systemAgent.add(systemAgentDelegate: ttsSpeakingDelegate)
        
        let ttsSpeakingRawData =
        """
        {
          "header": {
            "namespace": "System",
            "name": "Exception",
            "messageId": "0",
            "dialogRequestId": "0",
            "version": "1.0"
          },
          "payload": {
            "code": "TTS_SPEAKING_EXCEPTION",
            "description": "{{STRING}}"
          }
        }
        """.data(using: .utf8)!
        
        testHandleDirective(rawData: ttsSpeakingRawData)
        wait(for: [ttsSpeakingExpectation], timeout: 1.0)
        systemAgent.remove(systemAgentDelegate: ttsSpeakingDelegate)
        
        // INTERNAL_SERVICE_EXCEPTION
        let internalServiceRawData =
        """
        {
          "header": {
            "namespace": "System",
            "name": "Exception",
            "messageId": "0",
            "dialogRequestId": "0",
            "version": "1.0"
          },
          "payload": {
            "code": "INTERNAL_SERVICE_EXCEPTION",
            "description": "{{STRING}}"
          }
        }
        """.data(using: .utf8)!

        testHandleDirective(rawData: internalServiceRawData)
    }
    
    // MARK: Events
    // TODO: - Need to add events
}

// MARK: - Private (Test)

private extension SystemAgentTests {
    func testHandleDirective(rawData: Data) {
        let dictionary: [String: Any]
        do {
            dictionary = try JSONSerialization.jsonObject(with: rawData, options: []) as! [String: Any]
        } catch {
            XCTFail("Failed to parse rawData to jsonObject")
            return
        }
        
        guard let directive = Downstream.Directive(directiveDictionary: dictionary) else {
            XCTFail("Failed to parse dictionary to directive")
            return
        }
        
        systemAgent.handleDirective(directive) { (result) in
            switch result {
            case .success:
                XCTAssert(true)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }
}

// MARK: - MockSystemAgentDelegate

class MockSystemAgentDelegate: SystemAgentDelegate {
    let code: SystemAgentExceptionCode.Fail
    let expectation: XCTestExpectation
    
    init(code: SystemAgentExceptionCode.Fail, expectation: XCTestExpectation) {
        self.code = code
        self.expectation = expectation
    }
    
    func systemAgentDidReceiveExceptionFail(code: SystemAgentExceptionCode.Fail) {
        XCTAssertEqual(self.code, code)
        expectation.fulfill()
    }
}
