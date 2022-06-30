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
public enum MediaPlayerAgentDirectivePayload {
    
    // MARK: Play
    
    /// <#Description#>
    public struct Play {
        
        // MARK: Play.Toggle
        
        /// <#Description#>
        public struct Toggle {
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
    }
    
    // MARK: Stop
    
    /// <#Description#>
    public struct Stop {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
    }
    
    // MARK: Search
    
    /// <#Description#>
    public struct Search {
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
    public struct Previous {
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
    }
    
    // MARK: Next
    
    /// <#Description#>
    public struct Next {
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
    }
    
    // MARK: Move
    
    /// <#Description#>
    public struct Move {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
        /// <#Description#>
        public let direction: String
        /// <#Description#>
        public let sec: String
    }
    
    // MARK: Pause
    
    /// <#Description#>
    public struct Pause {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
    }
    
    // MARK: Resume
    
    /// <#Description#>
    public struct Resume {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
    }
    
    // MARK: Rewind
    
    /// <#Description#>
    public struct Rewind {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
    }
    
    // MARK: Toggle
    
    /// <#Description#>
    public struct Toggle {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
        /// <#Description#>
        public let `repeat`: String?
        /// <#Description#>
        public let like: String?
        /// <#Description#>
        public let shuffle: String?
    }
    
    // MARK: GetInfo
    
    /// <#Description#>
    public struct GetInfo {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let token: String
    }
    
    // MARK: HandlePlaylist
    
    /// <#Description#>
    public struct HandlePlaylist {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let action: String
        /// <#Description#>
        public let target: String?
    }
    
    // MARK: HandleLyrics
    
    /// <#Description#>
    public struct HandleLyrics {
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let action: String
    }
}

// MARK: - MediaPlayerAgentDirectivePayload.Play + Codable

extension MediaPlayerAgentDirectivePayload.Play: Codable {
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
        asrText = try container.decodeIfPresent(String.self, forKey: .asrText)
        song = try container.decodeIfPresent(MediaPlayerAgentSong.self, forKey: .song)
        toggle = try container.decodeIfPresent(Toggle.self, forKey: .toggle)
        data = try? container.decodeIfPresent([String: AnyHashable].self, forKey: .data)
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

// MARK: - MediaPlayerAgentDirectivePayload.Stop + Codable

extension MediaPlayerAgentDirectivePayload.Stop: Codable {}

// MARK: - MediaPlayerAgentDirectivePayload.Play.Toggle + Codable

extension MediaPlayerAgentDirectivePayload.Play.Toggle: Codable {}

// MARK: - MediaPlayerAgentDirectivePayload.Search + Codable

extension MediaPlayerAgentDirectivePayload.Search: Codable {}

// MARK: - MediaPlayerAgentDirectivePayload.Previous + Codable

extension MediaPlayerAgentDirectivePayload.Previous: Codable {
    public enum CodingKeys: String, CodingKey {
        case playServiceId
        case token
        case action
        case target
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        playServiceId = try container.decode(String.self, forKey: .playServiceId)
        token = try container.decode(String.self, forKey: .token)
        action = try container.decode(String.self, forKey: .action)
        target = try container.decode(String.self, forKey: .target)
        data = try? container.decodeIfPresent([String: AnyHashable].self, forKey: .data)
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

// MARK: - MediaPlayerAgentDirectivePayload.Next + Codable

extension MediaPlayerAgentDirectivePayload.Next: Codable {
    public enum CodingKeys: String, CodingKey {
        case playServiceId
        case token
        case action
        case target
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        playServiceId = try container.decode(String.self, forKey: .playServiceId)
        token = try container.decode(String.self, forKey: .token)
        action = try container.decode(String.self, forKey: .action)
        target = try container.decode(String.self, forKey: .target)
        data = try? container.decodeIfPresent([String: AnyHashable].self, forKey: .data)
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

// MARK: - MediaPlayerAgentDirectivePayload.Move + Codable

extension MediaPlayerAgentDirectivePayload.Move: Codable {}

// MARK: - MediaPlayerAgentDirectivePayload.Pause + Codable

extension MediaPlayerAgentDirectivePayload.Pause: Codable {}

// MARK: - MediaPlayerAgentDirectivePayload.Resume + Codable

extension MediaPlayerAgentDirectivePayload.Resume: Codable {}

// MARK: - MediaPlayerAgentDirectivePayload.Rewind + Codable

extension MediaPlayerAgentDirectivePayload.Rewind: Codable {}

// MARK: - MediaPlayerAgentDirectivePayload.Toggle + Codable

extension MediaPlayerAgentDirectivePayload.Toggle: Codable {}

// MARK: - MediaPlayerAgentDirectivePayload.GetInfo + Codable

extension MediaPlayerAgentDirectivePayload.GetInfo: Codable {}

// MARK: - MediaPlayerAgentDirectivePayload.HandlePlaylist + Codable

extension MediaPlayerAgentDirectivePayload.HandlePlaylist: Codable {}

// MARK: - MediaPlayerAgentDirectivePayload.HandleLyrics + Codable

extension MediaPlayerAgentDirectivePayload.HandleLyrics: Codable {}
