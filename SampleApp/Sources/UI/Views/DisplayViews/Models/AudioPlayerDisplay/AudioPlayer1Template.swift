//
//  AudioPlayer1Template.swift
//  SampleApp
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

struct AudioPlayer1Template: Decodable {
    let template: Template
    
    struct Template: Decodable {
        let type: String
        let title: Title
        let content: Content
        let grammarGuide: [String]?
        
        struct Title: Decodable {
            let iconUrl: String?
            let text: String
        }
        
        struct Content: Decodable {
            let title: String
            let subtitle1: String
            let subtitle2: String?
            let imageUrl: String
            let durationSec: String?
            let backgroundImageUrl: String?
            let backgroundColor: String?
            let badgeImageUrl: String?
            let badgeMessage: String?
            let lyrics: AudioPlayerLyricsTemplate?
            let settings: AudioPlayerSettingsTemplate?
        }
    }
}
