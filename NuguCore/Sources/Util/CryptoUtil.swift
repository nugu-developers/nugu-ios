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
    
    private static func crypt(operation: Int, data: Data, key: String) -> Data? {
        guard let keyData = key.data(using: String.Encoding.utf8) else {
            return nil
        }
        
        return keyData.withUnsafeBytes { keyUnsafeRawBufferPointer in
            return data.withUnsafeBytes { dataUnsafeRawBufferPointer in
                // Give the data out some breathing room for PKCS7's padding.
                let dataOutSize: Int = data.count + kCCBlockSizeAES128 * 2
                let dataOut = UnsafeMutableRawPointer.allocate(byteCount: dataOutSize,
                                                               alignment: 1)
                defer { dataOut.deallocate() }
                var dataOutMoved: Int = 0
                let status = CCCrypt(CCOperation(operation),
                                     algoritm,
                                     options,
                                     keyUnsafeRawBufferPointer.baseAddress, keyData.count,
                                     nil,
                                     dataUnsafeRawBufferPointer.baseAddress, data.count,
                                     dataOut, dataOutSize, &dataOutMoved
                )
                guard status == kCCSuccess else { return nil }
                return Data(bytes: dataOut, count: dataOutMoved)
            }
        }
    }
    
    public static func encrypt(data: Data, key: String) -> Data? {
        return crypt(operation: kCCEncrypt, data: data, key: key)
    }
    
    public static func decrypt(data: Data, key: String) -> Data? {
        return crypt(operation: kCCDecrypt, data: data, key: key)
    }
}
