//
//  AudioPlayerTemplate.swift
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

struct AudioPlayerTemplate: Decodable {
    let template: Template
    
    enum CodingKeys: String, CodingKey {
        case template
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        template = try container.decode(Template.self, forKey: .template)
    }
    
    struct Template: Decodable {
        let type: String
        let title: Title
        let content: Content
        
        enum CodingKeys: String, CodingKey {
            case type
            case title
            case content
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(String.self, forKey: .type)
            title = try container.decode(Title.self, forKey: .title)
            content = try container.decode(Content.self, forKey: .content)
        }
        
        struct Title: Decodable {
            let iconUrl: String?
            let text: String
            
            enum CodingKeys: String, CodingKey {
                case iconUrl
                case text
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                iconUrl = try? container.decodeIfPresent(String.self, forKey: .iconUrl)
                text = try container.decode(String.self, forKey: .text)
            }
        }
        
        struct Content: Decodable {
            let title: String
            let subtitle: String?
            let subtitle1: String?
            let subtitle2: String?
            let imageUrl: String
            let durationSec: Int?
            let backgroundColor: String?
            let backgroundImageUrl: String?
            let badgeImageUrl: String?
            let badgeMessage: String?
            let lyrics: AudioPlayerLyricsTemplate?
            let settings: AudioPlayerSettingsTemplate?
            
            enum CodingKeys: String, CodingKey {
                case title
                case subtitle
                case subtitle1
                case subtitle2
                case imageUrl
                case durationSec
                case backgroundColor
                case backgroundImageUrl
                case badgeImageUrl
                case badgeMessage
                case lyrics
                case settings
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                title = try container.decode(String.self, forKey: .title)
                subtitle = try? container.decodeIfPresent(String.self, forKey: .subtitle)
                subtitle1 = try? container.decodeIfPresent(String.self, forKey: .subtitle1)
                subtitle2 = try? container.decodeIfPresent(String.self, forKey: .subtitle2)
                imageUrl = try container.decode(String.self, forKey: .imageUrl)
                durationSec = try? container.decodeIfPresent(Int.self, forKey: .durationSec)
                backgroundColor = try? container.decodeIfPresent(String.self, forKey: .backgroundColor)
                backgroundImageUrl = try? container.decodeIfPresent(String.self, forKey: .backgroundImageUrl)
                badgeImageUrl = try? container.decodeIfPresent(String.self, forKey: .badgeImageUrl)
                badgeMessage = try? container.decodeIfPresent(String.self, forKey: .badgeMessage)
                lyrics = try? container.decodeIfPresent(AudioPlayerLyricsTemplate.self, forKey: .lyrics)
                settings = try? container.decodeIfPresent(AudioPlayerSettingsTemplate.self, forKey: .settings)
            }
        }
    }
}
