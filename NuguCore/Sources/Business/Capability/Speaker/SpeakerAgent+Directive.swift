//
//  SpeakerAgent+Directive.swift
//  NuguCore
//
//  Created by yonghoonKwon on 23/05/2019.
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

extension SpeakerAgent {
    enum DirectiveTypeInfo: CaseIterable {
        case setMute
    }
}

// MARK: - DirectiveTypeInforable

extension SpeakerAgent.DirectiveTypeInfo: DirectiveTypeInforable {
    var namespace: String { "Speaker" }
    
    var name: String {
        switch self {
        case .setMute: return "SetMute"
        }
    }
    
    var medium: DirectiveMedium {
        switch self {
        case .setMute: return .audio
        }
    }
    
    var isBlocking: Bool {
        switch self {
        case .setMute: return false
        }
    }
}
