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

public struct MediaPlayerAgentContext: Encodable {
    
    // MARK: User
    
    public struct User: Encodable {
        public let isLogIn: String
        public let hasVoucher: String
        
        public init(isLogIn: String, hasVoucher: String) {
            self.isLogIn = isLogIn
            self.hasVoucher = hasVoucher
        }
    }
    
    // MARK: Playlist
    
    public struct Playlist: Encodable {
        public let type: String
        public let name: String
        public let number: String
        public let length: String
        public let currentSongOrder: String
        
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
    
    public struct Toggle: Encodable {
        public let `repeat`: String?
        public let shuffle: String?
        
        public init(
            `repeat`: String?,
            shuffle: String?
        ) {
            self.repeat = `repeat`
            self.shuffle = shuffle
        }
    }
    
    public let appStatus: String
    public let playerActivity: String
    public let user: User?
    public let currentSong: MediaPlayerAgentSong?
    public let playlist: Playlist?
    public let toggle: Toggle?
    
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
