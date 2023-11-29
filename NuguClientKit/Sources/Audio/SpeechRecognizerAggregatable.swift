//
//  SpeechRecognizerAggregatable.swift
//  NuguClientKit
//
//  Created by MinChul Lee on 2021/01/14.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
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

import NuguAgents
import NuguCore
import NuguUtils

public protocol SpeechRecognizerAggregatable: AnyObject {
    var delegate: SpeechRecognizerAggregatorDelegate? { get set }
    var useKeywordDetector: Bool { get set }
    
    /// Start ASR(`ASRAgentProcotol`) with microphone.
    /// - Parameters:
    ///   - initiator: The options for recognition.
    ///   - service: The service object that identifies external options.
    ///   - requestType: The type of recognition request.
    ///   - completion: The completion handler to call when the request is complete.
    func startListening(
        initiator: ASRInitiator,
        service: [String: AnyHashable]?,
        requestType: String?,
        completion: ((StreamDataState) -> Void)?
    )
    
    /// Start keyword detector with microphone.
    func startListeningWithTrigger(completion: ((Result<Void, Error>) -> Void)?)
    
    /// Stop microphone, keyword detector and ASR.
    func stopListening()
    
    func startMicInputProvider(requestingFocus: Bool, completion: @escaping (EndedUp<Error>) -> Void)
    
    func stopMicInputProvider(completion: (() -> Void)?)
}

public extension SpeechRecognizerAggregatable {
    /// Start ASR(`ASRAgentProcotol`) with microphone.
    /// - Parameters:
    ///   - initiator: The options for recognition.
    ///   - service: The service object that identifies external options.
    ///   - requestType: The type of recognition request.
    func startListening(
        initiator: ASRInitiator,
        service: [String: AnyHashable]? = nil,
        requestType: String? = nil
    ) {
        startListening(initiator: initiator, service: service, requestType: requestType, completion: nil)
    }
    
    func startListeningWithTrigger() {
        startListeningWithTrigger(completion: nil)
    }
    
    func stopMicInputProvider() {
        stopMicInputProvider(completion: nil)
    }
}
