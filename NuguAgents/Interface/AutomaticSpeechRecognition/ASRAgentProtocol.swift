//
//  ASRAgentProtocol.swift
//  NuguAgents
//
//  Created by MinChul Lee on 05/05/2019.
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

/// `ASRAgent` 는 사용자 음성을 서버로 전송하고 음성 인식 결과 및 연속 발화 directive 를 처리합니다.
public protocol ASRAgentProtocol: CapabilityAgentable {
    var expectSpeech: ASRExpectSpeech? { get }
    
    /// Adds a delegate to be notified of `ASRAgent` state changes.
    /// - Parameter delegate: The object to add.
    func add(delegate: ASRAgentDelegate)
    
    /// Removes a delegate from `ASRAgent`.
    /// - Parameter delegate: The object to remove.
    func remove(delegate: ASRAgentDelegate)
    
    /// This function asks the `ASRAgent` to send a Recognize Event to Server and start streaming from `AudioStream`, which transitions it to the `recognizing` state.
    ///
    /// This function can be called in `idle` and `expectingSpeech` state.
    ///
    /// - Parameters:
    ///   - initiator:
    ///   - completion: The completion handler to call when the request is complete.
    /// - Returns: The dialogRequestId for request.
    @discardableResult func startRecognition(
        options: ASROptions,
        completion: ((_ asrResult: ASRResult, _ dialogRequestId: String) -> Void)?
    ) -> String
    
    /// This function forces the `ASRAgent` back to the `idle` state.
    ///
    /// This function can be called in any state, and will end any Event which is currently in progress.
    func stopRecognition()
}

// MARK: - Default

public extension ASRAgentProtocol {
    @discardableResult func startRecognition(
        completion: ((_ asrResult: ASRResult, _ dialogRequestId: String) -> Void)?
    ) -> String {
        return startRecognition(options: ASROptions(), completion: completion)
    }
}
