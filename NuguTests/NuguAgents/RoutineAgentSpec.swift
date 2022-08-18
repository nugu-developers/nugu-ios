//
//  RoutineAgentSpec.swift
//  NuguTests
//
//  Created by 신정섭님/A.출시 on 2022/08/17.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
//

import Quick
import Nimble

import NuguAgents
import NuguCore

class RoutineAgentSpec: QuickSpec {
    override func spec() {
        describe("RoutineAgent") {
            var upstreamDataSender: MockUpstreamDataSender!
            var contextManger: FakeContextManager!
            var directiveSequencer: FakeDirectiveSequencer!
            var streamDataRouter: DummyStreamDataRouter!
            var textAgent: MockTextAgent!
            var asrAgent: DummyASRAgent!
 
            var sut: RoutineAgent!
            
            beforeEach {
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
            
            afterEach {
                sut = nil
                asrAgent = nil
                textAgent = nil
                streamDataRouter = nil
                directiveSequencer = nil
                contextManger = nil
                upstreamDataSender = nil
            }
            
            context("context") {
                var contextInfo: ContextInfo?
                var payload: [String: Any]?
                
                beforeEach {
                    waitUntil(timeout: .milliseconds(500)) { done in
                        sut.contextInfoProvider { context in
                            contextInfo = context
                            payload = context?.payload as? [String: Any]
                            done()
                        }
                    }
                }
                
                afterEach {
                    payload = nil
                    contextInfo = nil
                }
                
                it("name is same as the capabilityAgent name") {
                    expect(contextInfo?.name).to(equal(sut.capabilityAgentProperty.name))
                }
                
                it("payload contains the capabilityAgnet version") {
                    expect(payload?["version"] as? String).to(equal(sut.capabilityAgentProperty.version))
                }
            }
            
            context("receives `Start` directive with invalid payload") {
                beforeEach {
                    directiveSequencer.processDirective(Downstream.makeInvalidPayloadDirective(name: "Start"))
                }
                
                it("result is failed") {
                    expect(directiveSequencer.directiveResults).to(equal(DirectiveHandleResult.failed("Invalid payload")))
                }
            }
            
            context("receives `Start` directive") {
                let dialogRequestId = ""
                let playServiceId = ""
                beforeEach {
                    directiveSequencer.processDirective(
                        Downstream.makeStartDirective(
                            dialogRequestId: dialogRequestId,
                            playServiceId: playServiceId,
                            actions: []
                        )
                    )
                }
                
                it("routineItem is not nil") {
                    expect(sut.routineItem).toEventuallyNot(beNil())
                }
                
                it("result is finished") {
                    expect(directiveSequencer.directiveResults).to(equal(DirectiveHandleResult.finished))
                }
                
                it("state changes playing") {
                    expect(sut.state).toEventually(equal(RoutineState.playing))
                }
            }
            
            context("receives `Start` directive with text Action not including the action playServiceId") {
                let dialogRequestId = "dialogRequestId"
                let playServiceId = "playServiceId"
                let token = "token"
                let text = "text"
                beforeEach {
                    directiveSequencer.processDirective(
                        Downstream.makeStartDirective(
                            dialogRequestId: dialogRequestId,
                            playServiceId: playServiceId,
                            actions: [
                                Downstream.makeTextAction(playServiceId: nil, token: token, text: text)
                            ]
                        )
                    )
                }
                
                it("textAgent received normal type textInput") {
                    expect(textAgent.receivedText).toEventually(equal(text))
                    expect(textAgent.receivedToken).to(equal(token))
                    expect(textAgent.receivedType).to(equal(TextAgentRequestType.normal))
                }
            }
            
            context("receives `Start` directive with text Action including the action playServiceId") {
                let dialogRequestId = "dialogRequestId"
                let playServiceId = "playServiceId"
                let textPlayServiceId = "textPlayServiceId"
                let token = "token"
                let text = "text"
                beforeEach {
                    directiveSequencer.processDirective(
                        Downstream.makeStartDirective(
                            dialogRequestId: dialogRequestId,
                            playServiceId: playServiceId,
                            actions: [
                                Downstream.makeTextAction(playServiceId: textPlayServiceId, token: token, text: text)
                            ]
                        )
                    )
                }
                
                it("textAgent received specific TextInput") {
                    expect(textAgent.receivedText).toEventually(equal(text))
                    expect(textAgent.receivedToken).to(equal(token))
                    expect(textAgent.receivedType).to(equal(TextAgentRequestType.specific(playServiceId: textPlayServiceId)))
                }
            }
            
            context("receives `Start` directive with data Action") {
                let dialogRequestId = ""
                let playServiceId = ""
                let dataPlayServiceId = "dataPlayServiceId"
                let data: [String: AnyHashable] = [
                    "test1": "test1",
                    "test2": "test2"
                ]
                beforeEach {
                    directiveSequencer.processDirective(
                        Downstream.makeStartDirective(
                            dialogRequestId: dialogRequestId,
                            playServiceId: playServiceId,
                            actions: [
                                Downstream.makeDataAction(playServiceId: dataPlayServiceId, data: data)
                            ]
                        )
                    )
                }
                
                it("send `ActionTriggered` event") {
                    expect(upstreamDataSender.event?.header.type).toEventually(equal("Routine.ActionTriggered"))
                }
                
                it("equal to data action") {
                    expect(upstreamDataSender.event?.payload["playServiceId"] as? String).toEventually(equal(dataPlayServiceId))
                    expect(upstreamDataSender.event?.payload["data"] as? [String: AnyHashable]).to(equal(data))
                }
            }
            
            context("receives `Stop` directive with invalid payload") {
                beforeEach {
                    directiveSequencer.processDirective(Downstream.makeInvalidPayloadDirective(name: "Stop"))
                }
                
                it("result is failed") {
                    expect(directiveSequencer.directiveResults).to(equal(DirectiveHandleResult.failed("Invalid payload")))
                }
            }
            
            context("receives `Continue` with invalid payload") {
                beforeEach {
                    directiveSequencer.processDirective(Downstream.makeInvalidPayloadDirective(name: "Continue"))
                }
                
                it("result is failed") {
                    expect(directiveSequencer.directiveResults).to(equal(DirectiveHandleResult.failed("Invalid payload")))
                }
            }
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
