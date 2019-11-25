//
//  NuguTimeIntervalTests.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2019/11/22.
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

class TimeIntervallicTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNuguTimeInterval() {
        /// case: normal
        let normalTime = 10.5346
        XCTAssertEqual(NuguTimeInterval(seconds: normalTime).seconds, 10.5346)
        XCTAssertEqual(NuguTimeInterval(seconds: normalTime).milliseconds, 10534.6, accuracy: 10534.6.nextUp - 10534.6.nextDown) // Check accuracy
        XCTAssertEqual(NuguTimeInterval(milliseconds: normalTime).seconds, 0.0105346)
        XCTAssertEqual(NuguTimeInterval(milliseconds: normalTime).milliseconds, 10.5346)
        XCTAssertEqual(NuguTimeInterval(seconds: normalTime).truncatedSeconds, 10)
        XCTAssertEqual(NuguTimeInterval(seconds: normalTime).truncatedMilliSeconds, 10534)
        
        /// case: max
        let maxTime = Double.infinity
        XCTAssertEqual(NuguTimeInterval(seconds: maxTime).seconds, .infinity)
        XCTAssertEqual(NuguTimeInterval(seconds: maxTime).milliseconds, .infinity)
        XCTAssertEqual(NuguTimeInterval(milliseconds: maxTime).seconds, .infinity)
        XCTAssertEqual(NuguTimeInterval(milliseconds: maxTime).milliseconds, .infinity)
        XCTAssertEqual(NuguTimeInterval(seconds: maxTime).truncatedSeconds, .max)
        XCTAssertEqual(NuguTimeInterval(seconds: maxTime).truncatedMilliSeconds, .max)
        
        
        /// case: min
        let minTime = -Double.infinity
        XCTAssertEqual(NuguTimeInterval(seconds: minTime).seconds, -.infinity)
        XCTAssertEqual(NuguTimeInterval(seconds: minTime).milliseconds, -.infinity)
        XCTAssertEqual(NuguTimeInterval(milliseconds: minTime).seconds, -.infinity)
        XCTAssertEqual(NuguTimeInterval(milliseconds: minTime).milliseconds, -.infinity)
        XCTAssertEqual(NuguTimeInterval(seconds: minTime).truncatedSeconds, .min)
        XCTAssertEqual(NuguTimeInterval(seconds: minTime).truncatedMilliSeconds, .min)
        
        
        /// case: NaN(Not a number)
        let nanTime = Double.nan
        XCTAssertEqual(NuguTimeInterval(seconds: nanTime).seconds.isNaN, true)
        XCTAssertEqual(NuguTimeInterval(seconds: nanTime).milliseconds.isNaN, true)
        XCTAssertEqual(NuguTimeInterval(milliseconds: nanTime).seconds.isNaN, true)
        XCTAssertEqual(NuguTimeInterval(milliseconds: nanTime).milliseconds.isNaN, true)
        XCTAssertEqual(NuguTimeInterval(seconds: nanTime).truncatedSeconds, 0)
        XCTAssertEqual(NuguTimeInterval(seconds: nanTime).truncatedMilliSeconds, 0)
        
        /// case: signalingNaN(Signaling not a number)
        let signalingNaNTime = Double.signalingNaN
        XCTAssertEqual(NuguTimeInterval(seconds: signalingNaNTime).seconds.isNaN, true)
        XCTAssertEqual(NuguTimeInterval(seconds: signalingNaNTime).milliseconds.isNaN, true)
        XCTAssertEqual(NuguTimeInterval(milliseconds: signalingNaNTime).seconds.isNaN, true)
        XCTAssertEqual(NuguTimeInterval(milliseconds: signalingNaNTime).milliseconds.isNaN, true)
        XCTAssertEqual(NuguTimeInterval(seconds: signalingNaNTime).truncatedSeconds, 0)
        XCTAssertEqual(NuguTimeInterval(seconds: signalingNaNTime).truncatedMilliSeconds, 0)
    }
}
