//
//  ExtensionAgentTests.swift
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

import XCTest

@testable import NuguAgents
@testable import NuguCore

class ExtensionAgentTests: XCTestCase {
    
    // NuguCore(Mock)
    let contextManager: ContextManageable = MockContextManager()
    let upstreamDataSender: UpstreamDataSendable = MockStreamDataRouter()
    let directiveSequencer: DirectiveSequenceable = MockDirectiveSequencer()
    
    // NuguAgents
    lazy var extensionAgent: ExtensionAgent = ExtensionAgent(
        upstreamDataSender: upstreamDataSender,
        contextManager: contextManager,
        directiveSequencer: directiveSequencer
    )
    
    // Override
    override func setUp() {
        extensionAgent.delegate = self
    }
    
    override func tearDown() {
        extensionAgent.delegate = nil
    }
    
    // MARK: Context
    
    func testContext() {
        /* Expected context
        {
             "Extension": {
                 "version": "1.1",
                 "data": {
                     "test": "context"
                 }
             }
         }
        */
        extensionAgent.contextInfoRequestContext { [weak self] (contextInfo) in
            guard let self = self else {
                XCTFail("self is nil")
                return
            }
            
            guard let contextInfo = contextInfo else {
                XCTFail("contextInfo is nil")
                return
            }
            
            XCTAssertEqual(contextInfo.name, self.extensionAgent.capabilityAgentProperty.name)
            
            guard let payload = contextInfo.payload as? [String: Any] else {
                XCTFail("payload is nil or not dictionary")
                return
            }
            
            XCTAssertEqual(payload["version"] as? String, self.extensionAgent.capabilityAgentProperty.version)
            
            guard let data = payload["data"] as? [String: Any] else {
                XCTFail("payload[\"data\"] is nil or not dictionary")
                return
            }
            
            XCTAssertEqual(data["test"] as? String, "context")
        }
    }
    
    // MARK: Directives
    
    func testActionDirective() {
        let rawData =
        """
        {
          "header": {
            "namespace": "Extension",
            "name": "Action",
            "messageId": "0",
            "dialogRequestId": "0",
            "version": "1.0"
          },
          "payload": {
            "playServiceId": "0",
            "data": {
               "test": "action"
            }
          }
        }
        """.data(using: .utf8)!
        
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
        
        extensionAgent.handleDirective(directive) { (result) in
            switch result {
            case .success:
                XCTAssert(true)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    // MARK: Events
    // TODO: - Need to add events
}

// MARK: - ExtensionAgentDelegate

extension ExtensionAgentTests: ExtensionAgentDelegate {
    func extensionAgentRequestContext() -> [String: Any]? {
        return [
            "test": "context"
        ]
    }
    
    func extensionAgentDidReceiveAction(data: [String: Any], playServiceId: String, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}
