//
//  XDirectiveSequencerTest.swift
//  NuguTests
//
//  Created by MinChul Lee on 2020/10/13.
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

import NuguCore
import NuguAgents

class XDirectiveSequencerTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let directiveSequencer = DirectiveSequencer()
        
        var infos = [DirectiveHandleInfos]()
        var expectations = [XCTestExpectation]()
        (0..<10).forEach { (namespace) in
            var infoList = [DirectiveHandleInfo]()
            (0..<10).forEach { (name) in
                let info = DirectiveHandleInfo(
                    namespace: "\(namespace)",
                    name: "\(name)",
                    blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true),
                    directiveHandler: handleDirective
                )
                infoList.append(info)
            }
            expectations.append(XCTestExpectation())
            infos.append(infoList.asDictionary)
        }
        
        infos.forEach { (info) in
            DispatchQueue.global().async {
                directiveSequencer.add(directiveHandleInfos: info)
            }
        }

        for (index, info) in infos.enumerated() {
            DispatchQueue.global().async {
                directiveSequencer.remove(directiveHandleInfos: info)
                expectations[index].fulfill()
            }
        }
        
        wait(for: expectations, timeout: 10.0)
    }
    
    func handleDirective() -> HandleDirective {
        return { directive, completion in
            completion(.finished)
        }
    }
}
