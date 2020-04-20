//
//  CapabilityAgentCategory.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 27/05/2019.
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

public enum CapabilityAgentCategory: CaseIterable {
    case audioPlayer
    case automaticSpeechRecognition
    case textToSpeech
    case display
    case system
    case text
    case `extension`
    case location
    case sound
}

public extension CapabilityAgentCategory {
    var name: String {
        switch self {
        case .audioPlayer: return "AudioPlayer"
        case .automaticSpeechRecognition: return "ASR"
        case .textToSpeech: return "TTS"
        case .display: return "Display"
        case .system: return "System"
        case .text: return "Text"
        case .extension: return "Extension"
        case .location: return "Location"
        case .sound: return "Sound"
        }
    }
}
