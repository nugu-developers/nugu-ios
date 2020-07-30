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

public struct MediaPlayerAgentDirectivePayload {
    
    // MARK: Play
    
    public struct Play: Decodable {
        public struct Toggle: Decodable {
            public let `repeat`: String?
            public let shuffle: String?
        }
        
        public let playServiceId: String
        public let token: String
        public let action: String
        public let asrText: String?
        public let song: MediaPlayerAgentSong?
        public let toggle: Toggle?
        public let data: [String: AnyHashable]?
        
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
    }
    
    // MARK: Search
    
    public struct Search: Decodable {
        public let playServiceId: String
        public let token: String
        public let asrText: String?
        public let song: MediaPlayerAgentSong?
    }
    
    // MARK: Previous
    
    public struct Previous: Decodable {
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
    }
    
    // MARK: Next
    
    public struct Next: Decodable {
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
    }
    
    // MARK: Move
    
    public struct Move: Decodable {
        public let playServiceId: String
        public let token: String
        public let direction: String
        public let sec: String
    }
    
    // MARK: Toggle
    
    public struct Toggle: Decodable {
        public let playServiceId: String
        public let token: String
        public let `repeat`: String?
        public let like: String?
        public let shuffle: String?
    }
}
