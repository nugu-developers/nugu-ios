//
//  KeyedDecodingContainerExtension.swift
//  NuguAgents
//
//  Created by DCs-OfficeMBP on 28/11/2018.
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

private struct JSONCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer {
    func decode(_ type: [String: AnyHashable].Type, forKey key: K) throws -> [String: AnyHashable] {
        let container = try nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }
    
    func decode(_ type: [AnyHashable].Type, forKey key: K) throws -> [AnyHashable] {
        var container = try nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decode(_ type: [String: AnyHashable].Type) throws -> [String: AnyHashable] {
        var dictionary = [String: AnyHashable]()
        
        for key in allKeys {
            var value: AnyHashable {
                if let value = try? decode(Bool.self, forKey: key) {
                    return value
                } else if let value = try? decode(String.self, forKey: key) {
                    return value
                } else if let value = try? decode(Int.self, forKey: key) {
                    return value
                } else if let value = try? decode(Double.self, forKey: key) {
                    return value
                } else if let value = try? decode([String: AnyHashable].self, forKey: key) {
                    return value
                } else if let value = try? decode([AnyHashable].self, forKey: key) {
                    return value
                }
                
                return NSNull()
            }
            
            dictionary[key.stringValue] = value
        }

        return dictionary
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [AnyHashable].Type) throws -> [AnyHashable] {
        var array: [AnyHashable] = []
        while isAtEnd == false {
            if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode([String: AnyHashable].self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode(Array<AnyHashable>.self) {
                array.append(nestedArray)
            }
        }
        return array
    }

    mutating func decode(_ type: [String: AnyHashable].Type) throws -> [String: AnyHashable] {
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}
