//
//  AudioPlayerDisplayTemplate.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2019/07/03.
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

/// <#Description#>
public struct AudioPlayerDisplayTemplate {
    /// <#Description#>
    public let header: Downstream.Header
    /// <#Description#>
    public let type: String
    /// <#Description#>
    public let payload: [String: AnyHashable]
    /// <#Description#>
    public let mediaPayload: MediaPayload
    /// <#Description#>
    public let isSeekable: Bool
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - payload: <#payload description#>
    ///   - templateId: <#templateId description#>
    ///   - dialogRequestId: <#dialogRequestId description#>
    ///   - mediaPayload: <#mediaPayload description#>
    ///   - isSeekable: <#isSeekable description#>
    init(header: Downstream.Header, type: String, payload: [String: AnyHashable], mediaPayload: MediaPayload, isSeekable: Bool) {
        self.header = header
        self.type = type
        self.payload = payload
        self.mediaPayload = mediaPayload
        self.isSeekable = isSeekable
    }
    
    /// <#Description#>
    public struct MediaPayload {
        /// <#Description#>
        public let token: String
        /// <#Description#>
        public let playServiceId: String
        /// <#Description#>
        public let playStackControl: PlayStackControl?
    }
}

public extension AudioPlayerDisplayTemplate {
    /// <#Description#>
    var templateId: String {
        header.messageId
    }
    /// <#Description#>
    var dialogRequestId: String {
        header.dialogRequestId
    }
}
