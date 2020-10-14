//
//  MediaPlayerAgentSong.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/07/10.
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
public struct MediaPlayerAgentSong: Codable {
    
    // MARK: Category
    
    /// <#Description#>
    public enum Category: String, Codable {
        case none = "NONE"
        case recommend = "RECOMMEND"
        case popular = "POPULAR"
        case new = "NEW"
        case chart = "CHART"
        case recentPlayed = "RECENT_PLAYED"
        case favorite = "FAVORITE"
        case likeSong = "LIKE_SONG"
        case likeAlbum = "LIKE_ALBUM"
        case likeArtist = "LIKE_ARTIST"
        case likeTheme = "LIKE_THEME"
        case playlist = "PLAYLIST"
        case nowplaying = "NOWPLAYING"
    }
    
    /// <#Description#>
    public let category: Category
    /// <#Description#>
    public let theme: String?
    /// <#Description#>
    public let genre: [String]?
    /// <#Description#>
    public let artist: [String]?
    /// <#Description#>
    public let album: String?
    /// <#Description#>
    public let title: String?
    /// <#Description#>
    public let duration: String?
    /// <#Description#>
    public let issueDate: String?
    /// <#Description#>
    public let etc: [String: AnyHashable]?
    
    enum CodingKeys: String, CodingKey {
        case category
        case theme
        case genre
        case artist
        case album
        case title
        case duration
        case issueDate
        case etc
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        category = try container.decode(Category.self, forKey: .category)
        theme = try container.decodeIfPresent(String.self, forKey: .theme)
        genre = try container.decodeIfPresent([String].self, forKey: .genre)
        artist = try container.decodeIfPresent([String].self, forKey: .artist)
        album = try container.decodeIfPresent(String.self, forKey: .album)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        duration = try container.decodeIfPresent(String.self, forKey: .duration)
        issueDate = try container.decodeIfPresent(String.self, forKey: .issueDate)
        etc = try container.decode([String: AnyHashable].self, forKey: .etc)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - category: <#category description#>
    ///   - theme: <#theme description#>
    ///   - genre: <#genre description#>
    ///   - artist: <#artist description#>
    ///   - album: <#album description#>
    ///   - title: <#title description#>
    ///   - duration: <#duration description#>
    ///   - issueDate: <#issueDate description#>
    ///   - etc: <#etc description#>
    public init(
        category: Category,
        theme: String?,
        genre: [String]?,
        artist: [String]?,
        album: String?,
        title: String?,
        duration: String?,
        issueDate: String?,
        etc: [String: AnyHashable]?
    ) {
        self.category = category
        self.theme = theme
        self.genre = genre
        self.artist = artist
        self.album = album
        self.title = title
        self.duration = duration
        self.issueDate = issueDate
        self.etc = etc
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(category, forKey: .category)
        try container.encode(theme, forKey: .theme)
        try container.encode(genre, forKey: .genre)
        try container.encode(artist, forKey: .artist)
        try container.encode(album, forKey: .album)
        try container.encode(title, forKey: .title)
        try container.encode(theme, forKey: .theme)
        try container.encode(duration, forKey: .duration)
        try container.encode(issueDate, forKey: .issueDate)
        try container.encodeIfPresent(etc, forKey: .etc)
    }
}
