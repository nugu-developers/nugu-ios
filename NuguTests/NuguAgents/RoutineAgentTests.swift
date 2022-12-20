//
//  RoutineAgentTests.swift
//  NuguTests
//
//  Created by jaycesub on 2022/08/22.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
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

class RoutineAgentTests: XCTestCase {
    var sut: RoutineAgent!
    var upstreamDataSender: MockUpstreamDataSender!
    var contextManger: FakeContextManager!
    var directiveSequencer: FakeDirectiveSequencer!
    var streamDataRouter: DummyStreamDataRouter!
    var textAgent: MockTextAgent!
    var asrAgent: DummyASRAgent!
    
    override func setUpWithError() throws {
        upstreamDataSender = MockUpstreamDataSender()
        contextManger = FakeContextManager()
        directiveSequencer = FakeDirectiveSequencer()
        streamDataRouter = DummyStreamDataRouter()
        textAgent = MockTextAgent()
        asrAgent = DummyASRAgent()
        sut = RoutineAgent(
            upstreamDataSender: upstreamDataSender,
            contextManager: contextManger,
            directiveSequencer: directiveSequencer,
            streamDataRouter: streamDataRouter,
            textAgent: textAgent,
            asrAgent: asrAgent
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        asrAgent = nil
        textAgent = nil
        streamDataRouter = nil
        directiveSequencer = nil
        contextManger = nil
        upstreamDataSender = nil
    }
    
    func testContextInfo() {
        let expectation = expectation(description: "contextInfo")
        var contextInfo: ContextInfo?
        var payload: [String: Any]?
        
        sut.contextInfoProvider { context in
            contextInfo = context
            payload = context?.payload as? [String: Any]
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(contextInfo?.name, sut.capabilityAgentProperty.name)
        XCTAssertEqual(payload?["version"] as? String, sut.capabilityAgentProperty.version)
    }
    
    func testStartDirectiveWithInvalidPayload() {
        directiveSequencer.processDirective(Downstream.makeInvalidPayloadDirective(name: "Start"))
        
        XCTAssertEqual(directiveSequencer.directiveResults, .failed("Invalid payload"))
    }
    
    func testStartDirective() {
        directiveSequencer.processDirective(
            Downstream.makeStartDirective(
                dialogRequestId: "",
                playServiceId: "",
                actions: []
            )
        )
        expectToEventually(sut.routineItem != nil)
        XCTAssertEqual(directiveSequencer.directiveResults, .finished)
        XCTAssertEqual(sut.state, .playing)
    }
    
    func testStartDirectiveWithTextActionNotIncludingTheActionPlayServiceId() {
        let dialogRequestId = "dialogRequestId"
        let playServiceId = "playServiceId"
        let token = "token"
        let text = "text"
        
        directiveSequencer.processDirective(
            Downstream.makeStartDirective(
                dialogRequestId: dialogRequestId,
                playServiceId: playServiceId,
                actions: [
                    Downstream.makeTextAction(playServiceId: nil, token: token, text: text)
                ]
            )
        )
        
        expectToEventually(textAgent.receivedText == text)
        XCTAssertEqual(textAgent.receivedToken, token)
        XCTAssertEqual(textAgent.receivedType, TextAgentRequestType.normal)
    }
    
    func testStartDirectiveWithTextActionIncludingTheActionPlayServiceId() {
        let dialogRequestId = "dialogRequestId"
        let playServiceId = "playServiceId"
        let textPlayServiceId = "textPlayServiceId"
        let token = "token"
        let text = "text"
        
        directiveSequencer.processDirective(
            Downstream.makeStartDirective(
                dialogRequestId: dialogRequestId,
                playServiceId: playServiceId,
                actions: [
                    Downstream.makeTextAction(playServiceId: textPlayServiceId, token: token, text: text)
                ]
            )
        )
        
        expectToEventually(textAgent.receivedText == text)
        XCTAssertEqual(textAgent.receivedToken, token)
        XCTAssertEqual(textAgent.receivedType, TextAgentRequestType.specific(playServiceId: textPlayServiceId))
    }
    
    func testStartDirectiveWithDataAction() {
        let dialogRequestId = ""
        let playServiceId = ""
        let dataPlayServiceId = "dataPlayServiceId"
        let data: [String: AnyHashable] = [
            "test1": "test1",
            "test2": "test2"
        ]
        
        directiveSequencer.processDirective(
            Downstream.makeStartDirective(
                dialogRequestId: dialogRequestId,
                playServiceId: playServiceId,
                actions: [
                    Downstream.makeDataAction(playServiceId: dataPlayServiceId, data: data)
                ]
            )
        )
        
        expectToEventually(upstreamDataSender.event?.header.type == "Routine.ActionTriggered")
        XCTAssertEqual(upstreamDataSender.event?.payload["playServiceId"] as? String, dataPlayServiceId)
        XCTAssertEqual(upstreamDataSender.event?.payload["data"] as? [String: AnyHashable], data)
    }
    
    func testStopDirectiveWithInvalidPayload() {
        directiveSequencer.processDirective(Downstream.makeInvalidPayloadDirective(name: "Stop"))
        
        XCTAssertEqual(directiveSequencer.directiveResults, .failed("Invalid payload"))
    }
    
    func testContinueDirectiveWithInvalidPayload() {
        directiveSequencer.processDirective(Downstream.makeInvalidPayloadDirective(name: "Continue"))
        
        XCTAssertEqual(directiveSequencer.directiveResults, .failed("Invalid payload"))
    }
}

private extension RoutineAgentTests {
    func expectToEventually(_ test: @autoclosure () -> Bool, timeout: TimeInterval = 1.0, message: String = "") {
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        repeat {
            if test() {
                return
            }
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        } while Date().compare(timeoutDate) == .orderedAscending
        XCTFail(message)
    }
    
    func waitUntil(timeout: TimeInterval = 0.01, closure: @escaping () -> Void) {
        let expectation = expectation(description: #function)
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1) { _ in
            closure()
        }
    }
}

private extension Downstream {
    static func makeInvalidPayloadDirective(name: String) -> Directive {
        let header = Downstream.Header(
            namespace: "Routine",
            name: name,
            dialogRequestId: "",
            messageId: "",
            version: ""
        )
        let payloadDic = [String: AnyHashable]()
        let payload = try! JSONSerialization.data(withJSONObject: payloadDic)
        return .init(header: header, payload: payload)
    }
    
    static func makeTextAction(playServiceId: String?, token: String?, text: String) -> [String: AnyHashable] {
        return [
            "type": "TEXT",
            "playServiceId": playServiceId,
            "token": token,
            "text": text
        ]
    }
    
    static func makeDataAction(playServiceId: String, data: [String: AnyHashable]) -> [String: AnyHashable] {
        return [
            "token": "",
            "type": "DATA",
            "playServiceId": playServiceId,
            "data": data
        ]
    }
    
    static func makeStartDirective(dialogRequestId: String, playServiceId: String, actions: [[String: AnyHashable]]) -> Directive {
        let header = Header(
            namespace: "Routine",
            name: "Start",
            dialogRequestId: dialogRequestId,
            messageId: "",
            version: ""
        )
        
        let payloadDic: [String: AnyHashable] = [
            "playServiceId": playServiceId,
            "token": "",
            "actions" : actions
        ]
        let payload = try! JSONSerialization.data(withJSONObject: payloadDic)
        
        return .init(header: header, payload: payload)
    }
}

