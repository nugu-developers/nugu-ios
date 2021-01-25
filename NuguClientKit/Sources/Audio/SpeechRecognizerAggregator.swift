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
    private var becomeActiveObserver: Any?
    private var audioSessionInterruptionObserver: Any?
    
    private let nuguClient: NuguClient
    private let micInputProvider: MicInputProvider
    private var audioSessionInterrupted = false
    private var micInputProviderDelay: DispatchTime = .now()
    
    private var startMicWorkItem: DispatchWorkItem?

    // Audio input source
    private let micQueue = DispatchQueue(label: "com.sktelecom.romaine.speech_recognizer")
    
    public var useKeywordDetector = true
    
    public init(nuguClient: NuguClient, micInputProvider: MicInputProvider) {
        self.nuguClient = nuguClient
        self.micInputProvider = micInputProvider
        
        micInputProvider.delegate = self
        
        asrStateObserver = nuguClient.asrAgent.observe(NuguAgentNotification.ASR.State.self, queue: .main) { [weak self] (notification) in
            guard let self = self else { return }
            
            switch notification.state {
            case .idle:
                if self.useKeywordDetector == true {
                    nuguClient.keywordDetector.start()
                } else {
                    nuguClient.keywordDetector.stop()
                }
            case .listening:
                nuguClient.keywordDetector.stop()
            case .expectingSpeech:
                self.startMicInputProvider(requestingFocus: true) { (success) in
                    guard success == true else {
                        log.debug("startMicInputProvider failed!")
                        nuguClient.asrAgent.stopRecognition()
                        return
                    }
                }
            default:
                break
            }
        }
        
        becomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: { [weak self] (_) in
            guard let self = self else { return }
            
            // When mic has been activated before interruption end notification has been fired,
            // Option's .shouldResume factor never comes in. (even when it has to be)
            // Giving small delay for starting mic can be a solution for this situation
            if self.audioSessionInterrupted == true {
                self.micInputProviderDelay = .now() + 0.5
            }
        })
        registerAudioSessionObservers()
    }
    
    deinit {
        if let asrStateObserver = asrStateObserver {
            notificationCenter.removeObserver(asrStateObserver)
        }
        if let becomeActiveObserver = becomeActiveObserver {
            notificationCenter.removeObserver(becomeActiveObserver)
        }
        removeAudioSessionObservers()
    }
}

// MARK: - SpeechRecognizerAggregatable

public extension SpeechRecognizerAggregator {
    @discardableResult
    func startListening(initiator: ASRInitiator, completion: ((StreamDataState) -> Void)? = nil) -> String {
        let dialogRequestId = nuguClient.asrAgent.startRecognition(initiator: initiator, completion: completion)
        startMicInputProvider(requestingFocus: true) { [weak self] success in
            guard success else {
                log.error("Start MicInputProvider failed")
                self?.nuguClient.asrAgent.stopRecognition()
                return
            }
        }
        
        return dialogRequestId
    }
    
    func startListeningWithTrigger() {
        if useKeywordDetector, nuguClient.keywordDetector.keywordSource != nil {
            nuguClient.keywordDetector.start()
            
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
            
            if self.micInputProviderDelay > .now() {
                DispatchQueue.global().asyncAfter(deadline: self.micInputProviderDelay, execute: startMicWorkItem)
            } else {
                DispatchQueue.global().async(execute: startMicWorkItem)
            }
        } else {
            nuguClient.keywordDetector.stop()
            stopMicInputProvider()
        }
    }
    
    func stopListening() {
        nuguClient.keywordDetector.stop()
        stopMicInputProvider()
        nuguClient.asrAgent.stopRecognition()
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
            
            self.nuguClient.audioSessionManager?.requestRecordPermission { [weak self] isGranted in
                guard let self = self else { return }
                guard isGranted else {
                    log.error("Record permission denied")
                    completion(false)
                    return
                }
                self.micQueue.async { [unowned self] in
                    defer {
                        log.debug("addEngineConfigurationChangeNotification")
                        self.nuguClient.audioSessionManager?.registerAudioEngineConfigurationObserver()
                    }
                    self.micInputProvider.stop()
                    
                    // Control center does not work properly when mixWithOthers option has been included.
                    // To avoid adding mixWithOthers option when audio player is in paused state,
                    // update audioSession should be done only when requesting focus
                    if requestingFocus {
                        self.nuguClient.audioSessionManager?.updateAudioSession(requestingFocus: requestingFocus)
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
            nuguClient.audioSessionManager?.removeAudioEngineConfigurationObserver()
        }
    }
}

// MARK: - MicInputProviderDelegate

extension SpeechRecognizerAggregator: MicInputProviderDelegate {
    public func micInputProviderDidReceive(buffer: AVAudioPCMBuffer) {
        if nuguClient.keywordDetector.state == .active {
            nuguClient.keywordDetector.putAudioBuffer(buffer: buffer)
        }
        
        if [.listening, .recognizing].contains(nuguClient.asrAgent.asrState) {
            nuguClient.asrAgent.putAudioBuffer(buffer: buffer)
        }
    }
}

// MARK: - private(AudioSessionObserver)

private extension SpeechRecognizerAggregator {
    func registerAudioSessionObservers() {
        removeAudioSessionObservers()
        
        audioSessionInterruptionObserver = notificationCenter.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil, using: { [weak self] (notification) in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            switch type {
            case .began:
                self?.audioSessionInterrupted = true
            case .ended:
                self?.audioSessionInterrupted = false
            @unknown default: break
            }
        })
    }
    
    func removeAudioSessionObservers() {
        if let audioSessionInterruptionObserver = audioSessionInterruptionObserver {
            NotificationCenter.default.removeObserver(audioSessionInterruptionObserver)
            self.audioSessionInterruptionObserver = nil
        }
    }
}
