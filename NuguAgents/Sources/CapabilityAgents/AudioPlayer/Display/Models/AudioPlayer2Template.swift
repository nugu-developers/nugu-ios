//
//  AudioPlayer2Template.swift
//  NuguAgents
//
//  Created by 박종상님/iOS클라이언트개발팀 on 2023/09/11.
//  Copyright © 2023 SK Telecom Co., Ltd. All rights reserved.
//

import Foundation
/// <#Description#>
public struct AudioPlayer2Template: Decodable {
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
            public let subtitle: String
            public let subtitle1: String?
            public let imageUrl: String?
            public let durationSec: String?
            public let backgroundColor: String?
            public let lyrics: AudioPlayerLyricsTemplate?
        }
    }
}
