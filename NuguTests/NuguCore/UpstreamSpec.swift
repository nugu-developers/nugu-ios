//
//  UpstreamSpec.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2020/03/20.
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

@testable import NuguCore

class UpstreamSpec: QuickSpec {
    
    override func spec() {
        describe("upstream") {
            describe("event") {
                let event = Upstream.Event(
                    payload: ["test": "value1"],
                    header: Upstream.Header(
                        namespace: "namespace1",
                        name: "name1",
                        version: "version1",
                        dialogRequestId: "dialogRequestId1",
                        messageId: "messageId1",
                        referrerDialogRequestId: "referrerDialogRequestId1"
                    ),
                    contextPayload: []
                )
                
                it("is headerString") {
                    let testHeaderValue = "{\"name\":\"name1\",\"version\":\"version1\",\"namespace\":\"namespace1\",\"messageId\":\"messageId1\",\"dialogRequestId\":\"dialogRequestId1\",\"referrerDialogRequestId\":\"referrerDialogRequestId1\"}"
                   
                    let object = try? JSONSerialization.jsonObject(with: testHeaderValue.data(using: .utf8)!, options: .fragmentsAllowed) as? [String: AnyHashable]
                    let secondObject = try? JSONSerialization.jsonObject(with: event.headerString.data(using: .utf8)!, options: .fragmentsAllowed) as? [String: AnyHashable]
                    
                    expect(object).to(equal(secondObject))
                }
            }
            
            describe("attachment") {
                // TODO: -
            }
        }
    }
}
