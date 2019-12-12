//
//  DialogState.swift
//  NuguInterface
//
//  Created by MinChul Lee on 18/04/2019.
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

/// Identifies the dialog state.
public enum DialogState {
    /// Ready for an interaction.
    case idle
    /// Expecting a response from the user.
    case expectingSpeech
    /// Passively listening.
    case listening
    /// Actively listening.
    case recognizing
    /// Waiting for a response from the server.
    case thinking
    /// Responding to a request with speech.
    /// - Parameter expectingSpeech: `ASRAgent` 가 연속발화로 인한 요청을 기다리는 상태인지를 나타냅니다.
    case speaking(expectingSpeech: Bool)
}

// MARK: - Equatable

extension DialogState: Equatable {}
