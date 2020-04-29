//
//  SoundMedia.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/04/07.
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

struct SoundMedia {
    let player: MediaPlayable
    let payload: Payload
    let dialogRequestId: String
    
    init(player: MediaPlayable, payload: Payload, dialogRequestId: String) {
        self.player = player
        self.payload = payload
        self.dialogRequestId = dialogRequestId
    }
    
    struct Payload {
        let beepName: SoundBeepName
        let playServiceId: String
    }
}

// MARK: - SoundMedia.Payload: Decodable

extension SoundMedia.Payload: Decodable {
    enum CodingKeys: String, CodingKey {
        case beepName
        case playServiceId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        beepName = try container.decode(SoundBeepName.self, forKey: .beepName)
        playServiceId = try container.decode(String.self, forKey: .playServiceId)
    }
}
