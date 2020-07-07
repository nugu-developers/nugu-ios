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

public struct AudioPlayerDisplayTemplate {
    public let type: String
    public let payload: [String: AnyHashable]
    public let templateId: String
    public let dialogRequestId: String
    public var token: String {
        mediaPayload.audioItem.stream.token
    }
    let mediaPayload: AudioPlayerAgentMedia.Payload
    
    init(type: String, payload: [String: AnyHashable], templateId: String, dialogRequestId: String, mediaPayload: AudioPlayerAgentMedia.Payload) {
        self.type = type
        self.payload = payload
        self.templateId = templateId
        self.dialogRequestId = dialogRequestId
        self.mediaPayload = mediaPayload
    }
}
