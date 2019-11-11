//
//  TTSAgent+Directive.swift
//  NuguCore
//
//  Created by yonghoonKwon on 24/04/2019.
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

extension TTSAgent {
    enum DirectiveTypeInfo: CaseIterable {
        case speak
        case stop
    }
}

// MARK: - DirectiveTypeInforable

extension TTSAgent.DirectiveTypeInfo: DirectiveTypeInforable {
    var namespace: String { "TTS" }
    
    var name: String {
        switch self {
        case .speak: return "Speak"
        case .stop: return "Stop"
        }
    }

    var medium: DirectiveMedium {
        switch self {
        case .speak: return .audio
        case .stop: return .none
        }
    }

    var isBlocking: Bool {
        switch self {
        case .speak: return true
        case .stop: return false
        }
    }
}
