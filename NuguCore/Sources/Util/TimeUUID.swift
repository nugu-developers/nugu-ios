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

/// A class that represents an immutable universally unique identifier.
///
/// A UUID represents a 128-bit value.
public struct TimeUUID {
    // seconds
    private static let baseTime = 1546300800000.0
    
    /// Returns a string created from the UUID
    public let hexString: String
    
    /// Creates an instance of an `TimeUUID`.
    public init() {
        var hexString = String()
        
        // MARK: Time: length 10
        let time = Date().timeIntervalSince1970 * 1000 - TimeUUID.baseTime
        hexString += String(format: "%010llx", UInt64(time))
        
        // MARK: Version: length 2
        hexString += String(format: "%02x", 0x01)
        
        // MARK: Hash: length 12
        let hashKey = AuthorizationStore.shared.authorizationToken ?? ""
        let data = Data(hashKey.utf8)
        var digest = [UInt8](repeating: 0, count: 20)
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        // sha1 의 앞 6자리만...
        let hexBytes = digest.prefix(6).map { String(format: "%02hhx", $0) }
        hexString += hexBytes.joined()
        
        // MARK: Random: length 8
        let random = UInt32.random(in: 0..<UInt32.max)
        hexString += String(format: "%08x", random)
        
        self.hexString = String(hexString)
    }
}
