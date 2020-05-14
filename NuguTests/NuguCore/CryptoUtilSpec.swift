//
//  CryptoUtilSpec.swift
//  NuguTests
//
//  Created by MinChul Lee on 2020/04/27.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
//

import Foundation

import Quick
import Nimble

@testable import NuguCore

class CryptoUtilSpec: QuickSpec {
    private let key = "CryptoUtilAesKey"
    
    override func spec() {
        
        // The original text must be the same as the decrypted text.
        describe("Original text") {
            let plainText = "This is plain text"
            
            it("should be the same as decrypted text ") {
                let plainData = plainText.data(using: .utf8)!
                let encryptedData = CryptoUtil.encrypt(data: plainData, key: self.key)!
                let decryptedData = CryptoUtil.decrypt(data: encryptedData, key: self.key)!
                let decryptedText = String(data: decryptedData, encoding: .utf8)!
                
                expect(decryptedText).to(equal(plainText))
            }
        }
    }
}
