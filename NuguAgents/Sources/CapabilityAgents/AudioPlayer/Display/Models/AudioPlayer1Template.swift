//
//  AudioPlayer1Template.swift
//  NuguUIKit
//
//  Created by jin kim on 2020/03/06.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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

/// <#Description#>
public struct AudioPlayer1Template: Decodable {
    public let template: Template
    
    public struct Template: Decodable {
        public let type: String
        public let title: Title
        public let content: Content
        public let grammarGuide: [String]?
        
        public struct Title: Decodable {
            public let iconUrl: String?
            public let text: String
        }
        
        public struct Content: Decodable {
            public let title: String
            public let subtitle1: String
            public let subtitle2: String?
            public let imageUrl: String
            public let durationSec: String?
            public let backgroundImageUrl: String?
            public let backgroundColor: String?
            public let badgeImageUrl: String?
            public let badgeMessage: String?
            public let lyrics: AudioPlayerLyricsTemplate?
            public let settings: AudioPlayerSettingsTemplate?
        }
    }
}
