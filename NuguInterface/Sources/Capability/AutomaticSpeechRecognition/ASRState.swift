//
//  ASRState.swift
//  NuguInterface
//
//  Created by MinChul Lee on 17/04/2019.
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

/// Identifies the ASRAgent state.
public enum ASRState {
    /// In this state, the ASRAgent is not waiting for or transmitting speech.
    case idle
    /// In this state, the ASRAgent is waiting for a call to recognize().
    case expectingSpeech
    /// In this state, the ASRAgent is passively streaming speech.
    case listening
    /// In this state, the ASRAgent is actively streaming speech.
    case recognizing
    /// In this state, the ASRAgent has finished streaming and is waiting for completion of an Event.
    case busy
}
