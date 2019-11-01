//
//  SpeakerMuteInfo.swift
//  NuguCore
//
//  Created by MinChul Lee on 2019/08/29.
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

import NuguInterface

struct SpeakerMuteInfo: Decodable {
    let playServiceId: String
    let volumes: [Volume]
    
    struct Volume: Decodable, Equatable {
        let name: SpeakerVolumeType
        let mute: Bool
    }
}

// MARK: - Array + SpeakerMuteInfo.Volume

extension Array where Element == SpeakerMuteInfo.Volume {
    var values: [[String: Any]] {
        return map { ["name": $0.name.rawValue, "mute": $0.mute] }
    }
}
