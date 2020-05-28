//
//  CryptoUtilSpec.swift
//  NuguTests
//
//  Created by MinChul Lee on 2020/04/27.
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
