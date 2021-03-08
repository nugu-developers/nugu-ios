//
//  ASRInitiator.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/09/21.
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

/// <#Description#>
public enum ASRInitiator: Equatable {
    case wakeUpWord(keyword: String?, data: Data, start: Int, end: Int, detection: Int)
    case pressAndHold
    case tap
    case expectSpeech
    case earset
}

extension ASRInitiator {
    var value: String {
        switch self {
        case .wakeUpWord: return "WAKE_UP_WORD"
        case .pressAndHold: return "PRESS_AND_HOLD"
        case .tap: return "TAP"
        case .expectSpeech: return "EXPECT_SPEECH"
        case .earset: return "EARSET"
        }
    }
}
