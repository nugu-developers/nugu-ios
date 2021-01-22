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
import AVFoundation

import NuguCore
import NuguUtils

/// ASR (AutomaticSpeechRecognition) is responsible for capturing the audio and delivering it to the server and receiving the result of speech recognition.
public protocol ASRAgentProtocol: CapabilityAgentable, TypedNotifyable {
    var options: ASROptions { get set }
    var asrState: ASRState { get }
    
    /// This function asks the `ASRAgent` to send a Recognize Event to Server and start streaming from `AudioStream`, which transitions it to the `recognizing` state.
    ///
    /// This function can be called in `idle` and `expectingSpeech` state.
    ///
    /// - Parameters:
    ///   - options: The options for recognition.
    ///   - completion: The completion handler to call when the request is complete.
    /// - Returns: The dialogRequestId for request.
    @discardableResult func startRecognition(
        initiator: ASRInitiator,
        completion: ((StreamDataState) -> Void)?
    ) -> String
    
    /// Put the audio buffer to be processed.
    func putAudioBuffer(buffer: AVAudioPCMBuffer)
    
    /// This function forces the `ASRAgent` back to the `idle` state.
    ///
    /// This function can be called in any state, and will end any Event which is currently in progress.
    func stopRecognition()
    
    /// This function asks the ASRAgent to stop streaming audio and end an ongoing Recognize Event, which transitions it to the BUSY state.
    ///
    /// This function can only be called in the LISTENING and RECOGNIZING state.
    func stopSpeech()
}

// MARK: - Default
public extension ASRAgentProtocol {
    /// This function asks the `ASRAgent` to send a Recognize Event to Server and start streaming from `AudioStream`, which transitions it to the `recognizing` state.
    ///
    /// This function can be called in `idle` and `expectingSpeech` state.
    ///
    /// - Parameters:
    ///   - options: The options for recognition.
    /// - Returns: The dialogRequestId for request.
    @discardableResult func startRecognition(initiator: ASRInitiator) -> String {
        return startRecognition(initiator: initiator, completion: nil)
    }
}
