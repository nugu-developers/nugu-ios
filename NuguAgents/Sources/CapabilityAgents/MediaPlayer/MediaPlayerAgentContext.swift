//
//  MediaPlayerAgentContext.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/07/14.
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
public struct MediaPlayerAgentContext: Codable {
    
    // MARK: User
    
    /// <#Description#>
    public struct User: Codable {
        /// <#Description#>
        public let isLogIn: String
        /// <#Description#>
        public let hasVoucher: String
        
        /// The initializer for `MediaPlayerAgentContext.User`.
        /// - Parameters:
        ///   - isLogIn: <#isLogIn description#>
        ///   - hasVoucher: <#hasVoucher description#>
        public init(isLogIn: String, hasVoucher: String) {
            self.isLogIn = isLogIn
            self.hasVoucher = hasVoucher
        }
    }
    
    // MARK: Playlist
    
    /// <#Description#>
    public struct Playlist: Codable {
        /// <#Description#>
        public let type: String
        /// <#Description#>
        public let name: String
        /// <#Description#>
        public let number: String
        /// <#Description#>
        public let length: String
        /// <#Description#>
        public let currentSongOrder: String
        
        /// The initializer for `MediaPlayerAgentContext.Playlist`.
        /// - Parameters:
        ///   - type: <#type description#>
        ///   - name: <#name description#>
        ///   - number: <#number description#>
        ///   - length: <#length description#>
        ///   - currentSongOrder: <#currentSongOrder description#>
        public init(
            type: String,
            name: String,
            number: String,
            length: String,
            currentSongOrder: String
        ) {
            self.type = type
            self.name = name
            self.number = number
            self.length = length
            self.currentSongOrder = currentSongOrder
        }
    }
    
    // MARK: Toggle
    
    /// <#Description#>
    public struct Toggle: Codable {
        /// <#Description#>
        public let `repeat`: String?
        /// <#Description#>
        public let shuffle: String?
        
        /// The initializer for `MediaPlayerAgentContext.Toggle`.
        /// - Parameters:
        ///   - repeat: <#repeat description#>
        ///   - shuffle: <#shuffle description#>
        public init(
            `repeat`: String?,
            shuffle: String?
        ) {
            self.repeat = `repeat`
            self.shuffle = shuffle
        }
    }
    
    /// <#Description#>
    public let appStatus: String
    /// <#Description#>
    public let playerActivity: String
    /// <#Description#>
    public let user: User?
    /// <#Description#>
    public let currentSong: MediaPlayerAgentSong?
    /// <#Description#>
    public let playlist: Playlist?
    /// <#Description#>
    public let toggle: Toggle?
    
    /// The initializer for `MediaPlayerAgentContext`.
    /// - Parameters:
    ///   - appStatus: <#appStatus description#>
    ///   - playerActivity: <#playerActivity description#>
    ///   - user: <#user description#>
    ///   - currentSong: <#currentSong description#>
    ///   - playlist: <#playlist description#>
    ///   - toggle: <#toggle description#>
    public init(
        appStatus: String,
        playerActivity: String,
        user: User?,
        currentSong: MediaPlayerAgentSong?,
        playlist: Playlist?,
        toggle: Toggle?
    ) {
        self.appStatus = appStatus
        self.playerActivity = playerActivity
        self.user = user
        self.currentSong = currentSong
        self.playlist = playlist
        self.toggle = toggle
    }
}
