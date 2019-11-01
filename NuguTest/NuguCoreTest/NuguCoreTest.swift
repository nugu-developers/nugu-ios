//
//  NuguCoreTest.swift
//  NuguCoreTest
//
//  Created by childc on 2019/10/23.
//  Copyright © 2019 sktelecom. All rights reserved.
//

import XCTest

import NuguCore

import RxSwift

class NuguCoreTest: XCTestCase {
    let disposeBag = DisposeBag()
    var index = 0

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func readBuffer(reader: SharedBuffer<Int>.Reader, complete: @escaping () -> Void) {
        reader.read { result in
            guard case .success(let element) = result else {
                XCTAssertTrue(self.index == 501)
                return
            }
            
            print("reader: \(element)")
            XCTAssertTrue(element == self.index)
            self.index += 1
            complete()
        }
    }
    
    func testSharedBuffer() {
        NuguApp.logEnabled = true
        let sharedBuffer = SharedBuffer<Int>(capacity: 5)
        let writer = sharedBuffer.makeBufferWriter()
        let reader = sharedBuffer.makeBufferReader()
        let expt = expectation(description: "Waiting done harkWork...")
        
        Observable<Int>.timer(RxTimeInterval.seconds(1), period: RxTimeInterval.milliseconds(3), scheduler: ConcurrentMainScheduler.instance)
            .subscribe(onNext: { index in
                do {
                    try writer.write(index)
                    print("writer: \(index)")
                    
                    if 500 == index {
                        writer.finish()
                    }
                } catch {
                    XCTAssert(false, "write failed")
                }
                
            }).disposed(by: disposeBag)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            var complete: (() -> Void)!
            complete = {
                self?.readBuffer(reader: reader, complete: complete)
            }
            
            self?.readBuffer(reader: reader, complete: complete)
        }
        
        Observable<Int>.timer(.seconds(3), scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
            .subscribe(onNext: { _ in
                expt.fulfill()
            }).disposed(by: disposeBag)
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }

}
