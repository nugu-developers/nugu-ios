//
//  JSONDecoder+decodeFromDictionary.swift
//  NuguUtils
//
//  Created by childc on 2021/01/18.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
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

public extension JSONDecoder {
    func decode<T>(_ type: T.Type, from dictionary: [AnyHashable: Any]?) throws -> T where T: Decodable {
        guard let dictionary = dictionary as? [String: Any] else { throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unmatched dictionary"))}
        
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        return try decode(type, from: data)
    }
}
