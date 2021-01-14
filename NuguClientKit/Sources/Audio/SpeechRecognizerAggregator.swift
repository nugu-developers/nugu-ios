//
//  SpeechRecognizerAggregator.swift
//  NuguClientKit
//
//  Created by MinChul Lee on 2021/01/14.
//  Copyright (c) 2021 SK Telecom Co., Ltd. All rights reserved.
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
import UIKit
import AVFoundation

import NuguAgents
import NuguCore

public class SpeechRecognizerAggregator: SpeechRecognizerAggregatable {
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var asrStateObserver: Any?
    
    private let asrAgent: ASRAgentProtocol
    private let keywordDetector: KeywordDetector
    private let micInputProvider: MicInputProvider
    private let audioSessionManager: AudioSessionManageable
    
    private var startMicWorkItem: DispatchWorkItem?

    // Audio input source
    private let micQueue = DispatchQueue(label: "com.sktelecom.romaine.speech_recognizer")
    
    public var useKeywordDetector = true
    
    public init(asrAgent: ASRAgentProtocol, keywordDetector: KeywordDetector, micInputProvider: MicInputProvider, audioSessionManager: AudioSessionManageable) {
        self.asrAgent = asrAgent
        self.keywordDetector = keywordDetector
        self.micInputProvider = micInputProvider
        self.audioSessionManager = audioSessionManager
        
        micInputProvider.delegate = self
        
        asrStateObserver = notificationCenter.addObserver(forName: .asrAgentStateDidChange, object: asrAgent, queue: .main) { [weak self] (notification) in
            guard let self = self else { return }
            guard let state = notification.userInfo?[ASRAgent.ObservingFactor.State.state] as? ASRState else { return }
            
            switch state {
            case .idle:
                if self.useKeywordDetector == true {
                    keywordDetector.start()
                } else {
                    keywordDetector.stop()
                }
            case .listening:
                keywordDetector.stop()
            case .expectingSpeech:
                self.startMicInputProvider(requestingFocus: true) { (success) in
                    guard success == true else {
                        log.debug("startMicInputProvider failed!")
                        asrAgent.stopRecognition()
                        return
                    }
                }
            default:
                break
            }
        }
    }
    
    deinit {
        if let asrStateObserver = asrStateObserver {
            notificationCenter.removeObserver(asrStateObserver)
        }
    }
}

// MARK: - SpeechRecognizerAggregatable

public extension SpeechRecognizerAggregator {
    @discardableResult
    func startListening(initiator: ASRInitiator, completion: ((StreamDataState) -> Void)? = nil) -> String {
        let dialogRequestId = asrAgent.startRecognition(initiator: initiator, completion: completion)
        startMicInputProvider(requestingFocus: true) { [weak self] success in
            guard success else {
                log.error("Start MicInputProvider failed")
                self?.asrAgent.stopRecognition()
                return
            }
        }
        
        return dialogRequestId
    }
    
    func startListeningWithTrigger() {
        if useKeywordDetector, keywordDetector.keywordSource != nil {
            keywordDetector.start()
            
            startMicWorkItem?.cancel()
            startMicWorkItem = DispatchWorkItem(block: { [weak self] in
                log.debug("startMicWorkItem start")
                self?.startMicInputProvider(requestingFocus: false) { (success) in
                    guard success else {
                        log.debug("startMicWorkItem failed!")
                        return
                    }
                }
            })
            guard let startMicWorkItem = startMicWorkItem else { return }
            // When mic has been activated before interruption end notification has been fired,
            // Option's .shouldResume factor never comes in. (even when it has to be)
            // Giving small delay for starting mic can be a solution for this situation
            // FIXME: Do not delay every time.
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5, execute: startMicWorkItem)
        } else {
            keywordDetector.stop()
            stopMicInputProvider()
        }
    }
    
    func stopListening() {
        keywordDetector.stop()
        stopMicInputProvider()
        asrAgent.stopRecognition()
    }
}

// MARK: - Private

extension SpeechRecognizerAggregator {
    func startMicInputProvider(requestingFocus: Bool, completion: @escaping (Bool) -> Void) {
        startMicWorkItem?.cancel()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard UIApplication.shared.applicationState == .active else {
                completion(false)
                return
            }
            
            self.audioSessionManager.requestRecordPermission { [weak self] isGranted in
                guard let self = self else { return }
                guard isGranted else {
                    log.error("Record permission denied")
                    completion(false)
                    return
                }
                self.micQueue.async { [unowned self] in
                    defer {
                        log.debug("addEngineConfigurationChangeNotification")
                        self.audioSessionManager.registerAudioEngineConfigurationObserver()
                    }
                    self.micInputProvider.stop()
                    
                    // Control center does not work properly when mixWithOthers option has been included.
                    // To avoid adding mixWithOthers option when audio player is in paused state,
                    // update audioSession should be done only when requesting focus
                    if requestingFocus {
                        self.audioSessionManager.updateAudioSession(requestingFocus: requestingFocus)
                    }
                    do {
                        try self.micInputProvider.start()
                        completion(true)
                    } catch {
                        log.error(error)
                        completion(false)
                    }
                }
            }
        }
    }
    
    func stopMicInputProvider() {
        micQueue.sync {
            startMicWorkItem?.cancel()
            micInputProvider.stop()
            audioSessionManager.removeAudioEngineConfigurationObserver()
        }
    }
}

// MARK: - MicInputProviderDelegate

extension SpeechRecognizerAggregator: MicInputProviderDelegate {
    public func micInputProviderDidReceive(buffer: AVAudioPCMBuffer) {
        if keywordDetector.state == .active {
            keywordDetector.putAudioBuffer(buffer: buffer)
        }
        
        if [.listening, .recognizing].contains(asrAgent.asrState) {
            asrAgent.putAudioBuffer(buffer: buffer)
        }
    }
}
