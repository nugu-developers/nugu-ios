//
//  KeyedEncodingContainerExtension.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/10/07.
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

extension KeyedEncodingContainer {
    public mutating func encode(_ value: [String: AnyHashable], forKey key: KeyedEncodingContainer<K>.Key) throws {
        var container = nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
        try container.encode(value)
    }

    public mutating func encode(_ value: [AnyHashable], forKey key: KeyedEncodingContainer<K>.Key) throws {
        var container = nestedUnkeyedContainer(forKey: key)
        try container.encode(value)
    }

    public mutating func encodeIfPresent(_ value: [String: AnyHashable]?, forKey key: KeyedEncodingContainer<K>.Key) throws {
        if let value = value {
            var container = nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
            try container.encode(value)
        } else {
            try encodeNil(forKey: key)
        }
    }

    public mutating func encodeIfPresent(_ value: [AnyHashable]?, forKey key: KeyedEncodingContainer<K>.Key) throws {
        if let value = value {
            var container = nestedUnkeyedContainer(forKey: key)
            try container.encode(value)
        } else {
            try encodeNil(forKey: key)
        }
    }
}

private extension KeyedEncodingContainer where K == JSONCodingKey {
    mutating func encode(_ value: [String: AnyHashable]) throws {
        for (dictKey, dictValue) in value {
            let key = JSONCodingKey(stringValue: dictKey)!
            switch dictValue {
            case is NSNull:
                try encodeNil(forKey: key)
            case let string as String:
                try encode(string, forKey: key)
            case let int as Int:
                try encode(int, forKey: key)
            case let bool as Bool:
                try encode(bool, forKey: key)
            case let double as Double:
                try encode(double, forKey: key)
            case let dict as [String: AnyHashable]:
                try encode(dict, forKey: key)
            case let array as [AnyHashable]:
                try encode(array, forKey: key)
            default:
                debugPrint("⚠️ Unsuported type!", dictValue)
                continue
            }
        }
    }
}

private extension UnkeyedEncodingContainer {
    mutating func encode(_ value: [AnyHashable]) throws {
        for arrayValue in value {
            switch arrayValue {
            case is NSNull:
                try encodeNil()
            case let string as String:
                try encode(string)
            case let int as Int:
                try encode(int)
            case let bool as Bool:
                try encode(bool)
            case let double as Double:
                try encode(double)
            case let dict as [String: AnyHashable]:
                try encode(dict)
            case let array as [AnyHashable]:
                var values = nestedUnkeyedContainer()
                try values.encode(array)
            default:
                debugPrint("⚠️ Unsuported type!", arrayValue)
            }
        }
    }
    
    mutating func encode(_ value: [String: AnyHashable]) throws {
        var container = self.nestedContainer(keyedBy: JSONCodingKey.self)
        try container.encode(value)
    }
}
