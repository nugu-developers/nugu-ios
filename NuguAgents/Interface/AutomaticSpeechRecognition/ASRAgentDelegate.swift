//
//  ASRAgentDelegate.swift
//  NuguAgents
//
//  Created by MinChul Lee on 01/05/2019.
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

/// An delegate that appllication can extend to register to observe `ASRAgent` state changes.
public protocol ASRAgentDelegate: class {
    /// Used to notify the observer of `ASRState` changes.
    /// - Parameter state: The new `ASRState` of the `ASRAgent`
    /// - Parameter expectSpeech: indicates `ASRState` is in progress with multiturn.
    func asrAgentDidChange(state: ASRState, expectSpeech: ASRExpectSpeech?)
    
    /// Called when received a result of `startRecognition` request.
    /// - Parameter result: A recognized result.
    func asrAgentDidReceive(result: ASRResult, dialogRequestId: String)
}
