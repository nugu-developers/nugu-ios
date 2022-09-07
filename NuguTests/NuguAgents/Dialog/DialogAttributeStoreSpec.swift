//
//  DialogAttributeStoreSpec.swift
//  NuguTests
//
//  Created by jayce1116 on 2022/05/24.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
//

import Quick
import Nimble

@testable import NuguAgents

class DialogAttributeStoreSpec: QuickSpec {
    
    override func spec() {
        var sut: DialogAttributeStore!
        
        
        describe("No attributes set") {
            beforeEach {
                sut = DialogAttributeStore()
            }
            
            afterEach {
                sut = nil
            }
            
            context("request attributes") {
                it("attributes not found") {
                    expect(sut.requestAttributes(key: nil)).to(beNil())
                }
            }
        }

        
        describe("set any attributes") {
            let expectedAttributes = ["": ""]
            let expectedMessageId = "expectedMessageId"
            beforeEach {
                sut = DialogAttributeStore()
                sut.setAttributes(expectedAttributes, key: expectedMessageId)
            }
            
            afterEach {
                sut = nil
            }
            
            context("request attributes") {
                it("get the attributes") {
                    expect(sut.requestAttributes(key: expectedMessageId)).to(equal(expectedAttributes))
                }
            }
            
            context("request attributes by wrong messageId") {
                it("get last set attributes") {
                    expect(sut.requestAttributes(key: "wrong messageId")).to(equal(expectedAttributes))
                }
            }
            
            context("request attributes by nil messageId") {
                it("get last set attributes") {
                    expect(sut.requestAttributes(key: nil)).to(equal(expectedAttributes))
                }
            }
            
            it("get the attributes") {
                expect(sut.getAttributes(key: expectedMessageId)).to(equal(expectedAttributes))
            }
            
            context("remove attributes") {
                beforeEach {
                    sut.removeAttributes(key: expectedMessageId)
                }
                it("attributes not found") {
                    expect(sut.requestAttributes(key: nil)).to(beNil())
                }
            }
            
            context("remove all attributes") {
                beforeEach {
                    sut.removeAllAttributes()
                }
                it("attributes not found") {
                    expect(sut.requestAttributes(key: nil)).to(beNil())
                }
            }
        }
    }
}
