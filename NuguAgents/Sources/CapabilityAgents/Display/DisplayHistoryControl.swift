//
//  DisplayHistoryControl.swift
//  NuguAgents
//
//  Created by 김진님/AI Assistant개발 Cell on 2021/10/20.
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

public struct DisplayHistoryControl {
    public let historyControl: HistoryControl
    
    public struct HistoryControl: Decodable {
        public let parent: Bool?
        public let child: Bool?
        public let parentToken: String?
        
        enum CodingKeys: String, CodingKey {
            case parent
            case child
            case parentToken
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            parent = try? container.decodeIfPresent(Bool.self, forKey: .parent)
            child = try? container.decodeIfPresent(Bool.self, forKey: .child)
            parentToken = try? container.decodeIfPresent(String.self, forKey: .parentToken)
        }
    }
}

// MARK: - Decodable

extension DisplayHistoryControl: Decodable {
    enum CodingKeys: String, CodingKey {
        case historyControl
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        historyControl = try container.decode(HistoryControl.self, forKey: .historyControl)
    }
}
