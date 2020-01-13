//
//  TimeUUID.swift
//  NuguCore
//
//  Created by MinChul Lee on 2019/06/21.
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

import Foundation
import CommonCrypto

public struct TimeUUID {
    // seconds
    private static let baseTime = 1546300800.0
    private static let maxRandom: UInt32 = (2 << 23) - 1
    
    // 32 * 4(hex string) = 128bit
    public let hexString: String
    
    public init() {
        var hexString = [Character]()
        
        // length 8
        let time = (Date().timeIntervalSince1970 - TimeUUID.baseTime) * 10
        String(format: "%08x", Int32(time)).forEach { (char) in
            hexString.append(char)
        }
        
        // length 2
        String(format: "%02x", 0x00).forEach { (char) in
            hexString.append(char)
        }
        
        // length 6
        let random = UInt32.random(in: 0..<TimeUUID.maxRandom)
        String(format: "%06x", random).forEach { (char) in
            hexString.append(char)
        }
        
        let hashKey = AuthorizationStore.shared.authorizationToken ?? ""
        // length 16
        let hash = { () -> String in
            let data = Data(hashKey.utf8)
            var digest = [UInt8](repeating: 0, count: 20)
            data.withUnsafeBytes {
                _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
            }
            // sha1 의 앞 8자리만...
            let hexBytes = digest.prefix(8).map { String(format: "%02hhx", $0) }
            return hexBytes.joined()
        }()
        hash.forEach { (char) in
            hexString.append(char)
        }
        
        self.hexString = String(hexString)
    }
}
