//
//  KeyedDecodingContainerExtension.swift
//  NuguUtils
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

public extension KeyedDecodingContainer {
    func decode(_ type: [String: AnyHashable].Type, forKey key: K) throws -> [String: AnyHashable] {
        let container = try nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
        return try container.decode(type)
    }
    
    func decode(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any] {
        let container = try nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
        return try container.decode(type)
    }
    
    func decode(_ type: [[String: AnyHashable]].Type, forKey key: K) throws -> [[String: AnyHashable]] {
        var container = try nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decode(_ type: [[String: Any]].Type, forKey key: K) throws -> [[String: Any]] {
        var container = try nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: [String: AnyHashable].Type, forKey key: K) throws -> [String: AnyHashable]? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decodeIfPresent(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any]? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decodeIfPresent(_ type: [[String: AnyHashable]].Type, forKey key: K) throws -> [[String: AnyHashable]]? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decodeIfPresent(_ type: [[String: Any]].Type, forKey key: K) throws -> [[String: Any]]? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decode(_ type: [AnyHashable].Type, forKey key: K) throws -> [AnyHashable] {
        var container = try nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
        var container = try nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decodeIfPresent(_ type: [AnyHashable].Type, forKey key: K) throws -> [AnyHashable]? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }
    
    func decodeIfPresent(_ type: [Any].Type, forKey key: K) throws -> [Any]? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
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
    
    func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        var dictionary = [String: Any]()
        
        for key in allKeys {
            var value: Any {
                if let value = try? decode(Bool.self, forKey: key) {
                    return value
                } else if let value = try? decode(String.self, forKey: key) {
                    return value
                } else if let value = try? decode(Int.self, forKey: key) {
                    return value
                } else if let value = try? decode(Double.self, forKey: key) {
                    return value
                } else if let value = try? decode([String: Any].self, forKey: key) {
                    return value
                } else if let value = try? decode([Any].self, forKey: key) {
                    return value
                }
                
                return NSNull()
            }
            
            dictionary[key.stringValue] = value
        }

        return dictionary
    }
    
    func decode(_ type: NSError.Type, forKey key: K) throws -> NSError {
        let container = try nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
        return try container.decode(type)
    }
}

private extension KeyedDecodingContainer where K == JSONCodingKey {
    func decode(_ type: NSError.Type) throws -> NSError {
        guard let code = try? decode(Int.self, forKey: JSONCodingKey(stringValue: "code")!) else { throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "code data not found")) }
        guard let domain = try? decode(String.self, forKey: JSONCodingKey(stringValue: "domain")!) else { throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "domain data not found")) }
        let userInfo = try? decode([String: Any].self, forKey: JSONCodingKey(stringValue: "userInfo")!)
        
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
}

private struct Dummy: Decodable {}

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
            } else if var container = try? nestedUnkeyedContainer(),
                      let nestedArray = try? container.decode([AnyHashable].self) {
                array.append(nestedArray)
            } else {
                _ = try decode(Dummy.self) // consume non-decodable

            }
        }
        return array
    }
    
    mutating func decode(_ type: [Any].Type) throws -> [Any] {
        var array: [Any] = []
        while isAtEnd == false {
            if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode([String: Any].self) {
                array.append(nestedDictionary)
            } else if var container = try? nestedUnkeyedContainer(),
                      let nestedArray = try? container.decode([Any].self) {
                array.append(nestedArray)
            } else {
                _ = try decode(Dummy.self) // consume non-decodable

            }
        }
        return array
    }
    
    mutating func decode(_ type: [[String: Any]].Type) throws -> [[String: Any]] {
        var array: [[String: Any]] = []
        while isAtEnd == false {
            if let value = try? decode([String: Any].self) {
                array.append(value)
            }
        }
        return array
    }
    
    mutating func decode(_ type: [[String: AnyHashable]].Type) throws -> [[String: AnyHashable]] {
        var array: [[String: AnyHashable]] = []
        while isAtEnd == false {
            if let value = try? decode([String: AnyHashable].self) {
                array.append(value)
            }
        }
        return array
    }

    mutating func decode(_ type: [String: AnyHashable].Type) throws -> [String: AnyHashable] {
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKey.self)
        return try nestedContainer.decode(type)
    }
    
    mutating func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKey.self)
        return try nestedContainer.decode(type)
    }
}
