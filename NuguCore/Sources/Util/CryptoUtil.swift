//
//  CryptoUtil.swift
//  NuguCore
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/04/06.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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
import CommonCrypto

public class CryptoUtil {
    private static let algoritm = CCAlgorithm(kCCAlgorithmAES)
    private static let options = CCOptions(kCCOptionECBMode|kCCOptionPKCS7Padding)
    
    public static func encrypt(data: Data, key: String) -> Data? {
        guard let keyData = key.data(using: String.Encoding.utf8) else {
            return nil
        }

        var numBytesEncrypted: size_t = 0
        let paddingSize = kCCBlockSizeAES128 - (data.count % kCCBlockSizeAES128)
        let encryptedData = Data(count: data.count + paddingSize)
        let cryptStatus = encryptedData.withUnsafeBytes { (ptrEncryptedData: UnsafePointer<UInt8>) -> CCStatus in
            keyData.withUnsafeBytes { (ptrKeyData: UnsafePointer<UInt8>) -> CCStatus in
                data.withUnsafeBytes { (ptrTargetData: UnsafePointer<UInt8>) -> CCStatus in
                    return CCCrypt(CCOperation(kCCEncrypt),
                                              algoritm,
                                              options,
                                              ptrKeyData, keyData.count,
                                              nil,
                                              ptrTargetData, data.count,
                                              UnsafeMutableRawPointer(mutating: ptrEncryptedData), encryptedData.count,
                                              &numBytesEncrypted)
                }
            }
        }
        
        guard cryptStatus == kCCSuccess else {
            return nil
        }
        
        return encryptedData
    }
    
    public static func decrypt(data: Data, key: String) -> Data? {
        guard let keyData = key.data(using: .utf8) else {
            return nil
        }
        
        var numBytesEncrypted: size_t = 0
        let decryptedData = Data(count: data.count)
        let cryptStatus = decryptedData.withUnsafeBytes { (ptrDecryptedData: UnsafePointer<UInt8>) -> CCStatus in
            keyData.withUnsafeBytes { (ptrKeyData: UnsafePointer<UInt8>) -> CCStatus in
                data.withUnsafeBytes { (ptrTargetData: UnsafePointer<UInt8>) -> CCStatus in
                    return CCCrypt(CCOperation(kCCDecrypt),
                                  algoritm,
                                  options,
                                  ptrKeyData, keyData.count,
                                  nil,
                                  ptrTargetData, data.count,
                                  UnsafeMutableRawPointer(mutating: ptrDecryptedData), decryptedData.count,
                                  &numBytesEncrypted)
                }
            }
        }
        
        guard cryptStatus == kCCSuccess else {
            return nil
        }
        
        // padding should be removed in decryption case.
        return decryptedData.subdata(in: 0 ..< numBytesEncrypted)
    }
}

extension Data {
    public func toHexString() -> String {
        return self.reduce("") {
            var hexString = String($1, radix: 16)
            if hexString.count == 1 {
                hexString = "0" + hexString
            }
            return $0 + hexString
        }
    }
}

