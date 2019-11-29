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

@testable import NuguInterface
@testable import NuguCore

class SystemAgentTests: XCTestCase {
    
    var exceptionPayload: [String: Any] = ["description": "test_description"]
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testException() {
        // Fail exception
        exceptionPayload["code"] = "UNAUTHORIZED_REQUEST_EXCEPTION"
        
        do {
            let data = try JSONSerialization.data(withJSONObject: exceptionPayload, options: [])
            let item = try JSONDecoder().decode(SystemAgentExceptionItem.self, from: data)
            
            XCTAssertEqual(item.code, .fail(code: .unauthorizedRequestException))
            XCTAssertNotEqual(item.code, .fail(code: .playRouterProcessingException))
            XCTAssertNotEqual(item.code, .warning(code: .internalServiceException))
        } catch {
            XCTFail()
        }
        
        // Warning exception
        exceptionPayload["code"] = "INTERNAL_SERVICE_EXCEPTION"
        
        do {
            let data = try JSONSerialization.data(withJSONObject: exceptionPayload, options: [])
            let item = try JSONDecoder().decode(SystemAgentExceptionItem.self, from: data)
            
            XCTAssertEqual(item.code, .warning(code: .internalServiceException))
            XCTAssertNotEqual(item.code, .warning(code: .asrRecognizingException))
            XCTAssertNotEqual(item.code, .fail(code: .unauthorizedRequestException))
        } catch {
            XCTFail()
        }
        
        // Parsing error
        exceptionPayload["code"] = "UNDEFINED_CODE"
        
        do {
            let data = try JSONSerialization.data(withJSONObject: exceptionPayload, options: [])
            let _ = try JSONDecoder().decode(SystemAgentExceptionItem.self, from: data)
            
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }
}
