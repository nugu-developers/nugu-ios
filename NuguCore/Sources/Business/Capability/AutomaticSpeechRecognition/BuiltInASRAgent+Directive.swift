//
//  BuiltInASRAgent+Directive.swift
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

extension BuiltInASRAgent {
    enum DirectiveTypeInfo: CaseIterable {
        case expectSpeech
        case notifyResult
    }
}

// MARK: - DirectiveTypeInforable

extension BuiltInASRAgent.DirectiveTypeInfo: DirectiveTypeInforable {
    var namespace: String { "ASR" }
    
    var name: String {
        switch self {
        case .expectSpeech: return "ExpectSpeech"
        case .notifyResult: return "NotifyResult"
        }
    }

    var medium: DirectiveMedium {
        switch self {
        case .expectSpeech: return .audio
        case .notifyResult: return .none
        }
    }

    var isBlocking: Bool {
        switch self {
        case .expectSpeech: return true
        case .notifyResult: return false
        }
    }
}
