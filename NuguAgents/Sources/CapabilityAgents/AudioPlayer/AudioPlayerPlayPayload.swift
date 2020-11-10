//
//  AudioPlayerPlayPayload.swift
//  NuguAgents
//
//  Created by MinChul Lee on 22/04/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
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

import NuguCore

struct AudioPlayerPlayPayload {
    let playStackControl: PlayStackControl?
    let sourceType: SourceType?
    let cacheKey: String?
    let audioItem: AudioItem
    let playServiceId: String
    
    enum SourceType: String, Decodable {
        case url = "URL"
        case attachment = "ATTACHMENT"
    }
    
    struct AudioItem {
        let stream: Stream
        let metadata: [String: AnyHashable]?
        
        struct Stream {
            let url: String?
            private let offsetInMilliseconds: Int
            fileprivate let progressReport: ProgressReport?
            let token: String
            let expectedPreviousToken: String?
            
            fileprivate struct ProgressReport {
                let delayInMilliseconds: Int?
                let intervalInMilliseconds: Int?
            }
        }
    }
}

extension AudioPlayerPlayPayload.AudioItem.Stream {
    var offset: Int {
        return offsetInMilliseconds / 1000
    }
    
    var delayReportTime: Int? {
        guard let delayInMilliseconds = progressReport?.delayInMilliseconds, delayInMilliseconds > 0 else { return nil }
        return delayInMilliseconds / 1000
    }
    
    var intervalReportTime: Int? {
        guard let intervalInMilliseconds = progressReport?.intervalInMilliseconds, intervalInMilliseconds > 0 else { return nil }
        return intervalInMilliseconds / 1000
    }
}

// MARK: - AudioPlayerPlayPayload: Decodable

extension AudioPlayerPlayPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case playStackControl
        case sourceType
        case cacheKey
        case audioItem
        case playServiceId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        playStackControl = try? container.decode(PlayStackControl.self, forKey: .playStackControl)
        if container.contains(.sourceType) {
            sourceType = try? container.decodeIfPresent(SourceType.self, forKey: .sourceType)
        } else {
            sourceType = .url
        }
        cacheKey = try? container.decodeIfPresent(String.self, forKey: .cacheKey)
        audioItem = try container.decode(AudioItem.self, forKey: .audioItem)
        playServiceId = try container.decode(String.self, forKey: .playServiceId)
    }
}

// MARK: - AudioPlayerPlayPayload.AudioItem: Decodable

extension AudioPlayerPlayPayload.AudioItem: Decodable {
    enum CodingKeys: String, CodingKey {
        case stream
        case metadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        stream = try container.decode(Stream.self, forKey: .stream)
        metadata = try? container.decodeIfPresent([String: AnyHashable].self, forKey: .metadata)
    }
}

// MARK: - AudioPlayerPlayPayload.Stream: Decodable

extension AudioPlayerPlayPayload.AudioItem.Stream: Decodable {
    enum CodingKeys: String, CodingKey {
        case url
        case offsetInMilliseconds
        case progressReport
        case token
        case expectedPreviousToken
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        url = try? container.decode(String.self, forKey: .url)
        offsetInMilliseconds = (try? container.decode(Int.self, forKey: .offsetInMilliseconds)) ?? 0
        progressReport = try? container.decode(ProgressReport.self, forKey: .progressReport)
        token = try container.decode(String.self, forKey: .token)
        expectedPreviousToken = try? container.decode(String.self, forKey: .expectedPreviousToken)
    }
}

// MARK: - AudioPlayerPlayPayload.Stream.ProgressReport: Decodable

extension AudioPlayerPlayPayload.AudioItem.Stream.ProgressReport: Decodable {
    enum CodingKeys: String, CodingKey {
        case progressReportDelayInMilliseconds
        case progressReportIntervalInMilliseconds
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        delayInMilliseconds = try? container.decode(Int.self, forKey: .progressReportDelayInMilliseconds)
        intervalInMilliseconds = try? container.decode(Int.self, forKey: .progressReportIntervalInMilliseconds)
    }
}
