//
//  MediaPlayerAgentDirectivePayload.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/07/24.
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

/// <#Description#>
public struct MediaPlayerAgentDirectivePayload {
    
    // MARK: Play
    
    /// <#Description#>
    public struct Play: Codable {
        /// <#Description#>
        public struct Toggle: Codable {
            /// <#Description#>
            public let `repeat`: String?
            /// <#Description#>
            public let shuffle: String?
        }
        
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
        /// <#Description#>
        public let action: String
        /// <#Description#>
        public let asrText: String?
        /// <#Description#>
        public let song: MediaPlayerAgentSong?
        /// <#Description#>
        public let toggle: Toggle?
        /// <#Description#>
        public let data: [String: AnyHashable]?
        
        /// <#Description#>
        enum CodingKeys: String, CodingKey {
            case playServiceId
            case token
            case action
            case asrText
            case song
            case toggle
            case data
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            playServiceId = try container.decode(String.self, forKey: .playServiceId)
            token = try container.decode(String.self, forKey: .token)
            action = try container.decode(String.self, forKey: .action)
            asrText = try? container.decodeIfPresent(String.self, forKey: .asrText)
            song = try? container.decodeIfPresent(MediaPlayerAgentSong.self, forKey: .song)
            toggle = try? container.decodeIfPresent(Toggle.self, forKey: .toggle)
            data = try? container.decode([String: AnyHashable].self, forKey: .data)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(playServiceId, forKey: .playServiceId)
            try container.encode(token, forKey: .token)
            try container.encode(action, forKey: .action)
            try container.encode(asrText, forKey: .asrText)
            try container.encode(song, forKey: .song)
            try container.encode(toggle, forKey: .toggle)
            try container.encodeIfPresent(data, forKey: .data)
        }
    }
    
    // MARK: Search
    
    /// <#Description#>
    public struct Search: Codable {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
        /// <#Description#>
        public let asrText: String?
        /// <#Description#>
        public let song: MediaPlayerAgentSong?
    }
    
    // MARK: Previous
    
    /// <#Description#>
    public struct Previous: Codable {
        /// <#Description#>
        public enum CodingKeys: String, CodingKey {
            case playServiceId
            case token
            case action
            case target
            case data
        }
        
        public let playServiceId: String
        public let token: String
        public let action: String
        public let target: String
        public let data: [String: AnyHashable]?
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            playServiceId = try container.decode(String.self, forKey: .playServiceId)
            token = try container.decode(String.self, forKey: .token)
            action = try container.decode(String.self, forKey: .action)
            target = try container.decode(String.self, forKey: .target)
            data = try? container.decode([String: AnyHashable].self, forKey: .data)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(playServiceId, forKey: .playServiceId)
            try container.encode(token, forKey: .token)
            try container.encode(action, forKey: .action)
            try container.encode(target, forKey: .target)
            try container.encodeIfPresent(data, forKey: .data)
        }
    }
    
    // MARK: Next
    
    /// <#Description#>
    public struct Next: Codable {
        public enum CodingKeys: String, CodingKey {
            case playServiceId
            case token
            case action
            case target
            case data
        }
        
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
        /// <#Description#>
        public let action: String
        /// <#Description#>
        public let target: String
        /// <#Description#>
        public let data: [String: AnyHashable]?
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            playServiceId = try container.decode(String.self, forKey: .playServiceId)
            token = try container.decode(String.self, forKey: .token)
            action = try container.decode(String.self, forKey: .action)
            target = try container.decode(String.self, forKey: .target)
            data = try? container.decode([String: AnyHashable].self, forKey: .data)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(playServiceId, forKey: .playServiceId)
            try container.encode(token, forKey: .token)
            try container.encode(action, forKey: .action)
            try container.encode(target, forKey: .target)
            try container.encodeIfPresent(data, forKey: .data)
        }
    }
    
    // MARK: Move
    
    /// <#Description#>
    public struct Move: Codable {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
        /// <#Description#>
        public let direction: String
        /// <#Description#>
        public let sec: String
    }
    
    // MARK: Toggle
    
    /// <#Description#>
    public struct Toggle: Codable {
        public let playServiceId: String
        public let token: String
        public let `repeat`: String?
        public let like: String?
        public let shuffle: String?
    }
}
