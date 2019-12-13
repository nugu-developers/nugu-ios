//
//  KeyChainHelper.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 13/12/2019.
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
import Security

class KeyChainHelper {
    private lazy var lock = NSLock()
    private let accessGroupId: String?
    private let service: String
    
    init(service: String, accessGroupId: String? = nil) {
        self.service = service
        self.accessGroupId = accessGroupId
    }
}

// MARK: - Set

extension KeyChainHelper {
    func setValue(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        try setValue(data, forKey: key)
    }
    
    func setValue(_ value: Bool, forKey key: String) throws {
        let bytes: [UInt8] = value ? [1] : [0]
        
        try setValue(Data(bytes), forKey: key)
    }
    
    func setValue(_ value: Data, forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        var deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service
        ]
        
        if let groupId = accessGroupId {
            deleteQuery[kSecAttrAccessGroup as String] = groupId
        }
        
        let deleteResultCode = SecItemDelete(deleteQuery as CFDictionary)
        if deleteResultCode != noErr {
            NSLog("(Not Important) No exist data: \(deleteResultCode)")
        }
        
        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleAlways
        ]
        
        if let groupId = accessGroupId {
            addQuery[kSecAttrAccessGroup as String] = groupId
        }
        
        let addResultCode = SecItemAdd(addQuery as CFDictionary, nil)
        guard addResultCode == noErr else {
            throw KeychainError.addQueryFailed(code: addResultCode)
        }
    }
}

// MARK: - Get

extension KeyChainHelper {
    func string(forKey key: String) throws -> String? {
        guard let data = try data(forKey: key) else {
            return nil
        }
        
        guard let stringValue = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        
        return stringValue
    }
    
    func bool(forKey key: String) throws -> Bool? {
        guard
            let data = try data(forKey: key),
            let firstBit = data.first
        else {
            return nil
        }
        
        return firstBit == 1
    }
    
    func data(forKey key: String) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }
        
        var copyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue!
        ]
        
        if let groupId = accessGroupId {
            copyQuery[kSecAttrAccessGroup as String] = groupId
        }
        
        var result: AnyObject?
        let resultCode = withUnsafeMutablePointer(to: &result) { (pointer) -> OSStatus in
            SecItemCopyMatching(copyQuery as CFDictionary, UnsafeMutablePointer(pointer))
        }
        
        guard resultCode == noErr else {
            throw KeychainError.copyQueryFailed(code: resultCode)
        }
        
        return result as? Data
    }
}

// MARK: - Delete

extension KeyChainHelper {
    func clear() throws {
        lock.lock()
        defer { lock.unlock() }
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        
        if let groupId = accessGroupId {
            query[kSecAttrAccessGroup as String] = groupId
        }
        
        let resultCode = SecItemDelete(query as CFDictionary)
        guard resultCode == noErr else {
            throw KeychainError.deleteQueryFailed(code: resultCode)
        }
    }
}

// MARK: - KeychainQueryError

enum KeychainError: Error {
    case deleteQueryFailed(code: OSStatus)
    case addQueryFailed(code: OSStatus)
    case copyQueryFailed(code: OSStatus)
    case encodingFailed
    case decodingFailed
}
