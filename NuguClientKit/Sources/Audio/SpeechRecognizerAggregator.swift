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
import NuguUtils

public class SpeechRecognizerAggregator: SpeechRecognizerAggregatable {
    public weak var delegate: SpeechRecognizerAggregatorDelegate?
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var asrStateObserver: Any?
    private var asrResultObserver: Any?
    private var becomeActiveObserver: Any?
    private var audioSessionInterruptionObserver: Any?
    
    private let asrAgent: ASRAgentProtocol
    private let keywordDetector: KeywordDetector
    
    private let micInputProvider = MicInputProvider()
    private var audioSessionInterrupted = false
    private var micInputProviderDelay: DispatchTime = .now()
    
    @Atomic private var startMicWorkItem: DispatchWorkItem?

    // Audio input source
    private let micQueue = DispatchQueue(label: "com.sktelecom.romaine.speech_recognizer")
    
    public var useKeywordDetector = true
    
    // State
    private(set) public var state: SpeechRecognizerAggregatorState = .idle {
        didSet {
            if state != oldValue {
                log.info("sra state: \(state)")
                delegate?.speechRecognizerStateDidChange(state)
            }
        }
    }
    
    public init(
        keywordDetector: KeywordDetector,
        asrAgent: ASRAgentProtocol
    ) {
        self.keywordDetector = keywordDetector
        self.asrAgent = asrAgent
        micInputProvider.delegate = self
        keywordDetector.delegate = self 
        
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
        
        addAsrStateObserver()
        addAsrResultObserver()
    }
    
    deinit {
        if let asrStateObserver = asrStateObserver {
            notificationCenter.removeObserver(asrStateObserver)
        }
        if let asrResultObserver = asrResultObserver {
            notificationCenter.removeObserver(asrResultObserver)
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
        switch state {
        case .cancelled,
             .idle,
             .error:
            break
        case .wakeupTriggering:
            keywordDetector.stop()
        default:
            asrAgent.stopRecognition()
        }
        
        let dialogRequestId = asrAgent.startRecognition(initiator: initiator) { [weak self] state in
            guard case .prepared = state else {
                completion?(state)
                return
            }
            
            self?.startMicInputProvider(requestingFocus: true) { [weak self] endedUp in
                if case let .failure(error) = endedUp {
                    log.error("Start MicInputProvider failed: \(error)")
                    self?.asrAgent.stopRecognition()
                    
                    var recognizerError: Error {
                        guard error is MicInputError else {
                            return error
                        }
                        
                        return SpeechRecognizerAggregatorError.cannotOpenMicInputForRecognition
                    }
                    self?.state = .error(recognizerError)
                    completion?(.error(recognizerError))
                    
                    return
                }
                
                completion?(.prepared)
            }
        }
        
        return dialogRequestId
    }
    
    func startListeningWithTrigger(completion: ((Result<Void, Error>) -> Void)?) {
        guard useKeywordDetector else { return }
        _startMicWorkItem.mutate {
            $0?.cancel()
            $0 = DispatchWorkItem(block: { [weak self] in
                log.debug("startMicWorkItem start")
                self?.startMicInputProvider(requestingFocus: false) { (endedUp) in
                    if case let .failure(error) = endedUp {
                        log.debug("startMicWorkItem failed: \(error)")
                        var recognizerError: Error {
                            guard error is MicInputError else {
                                return error
                            }
                            
                            return SpeechRecognizerAggregatorError.cannotOpenMicInputForWakeup
                        }
                        self?.state = .error(recognizerError)
                        completion?(.failure(recognizerError))
                        
                        return

                    }
                    
                    self?.keywordDetector.start()
                    completion?(.success(()))
                }
            })
        }
        guard let startMicWorkItem = self.startMicWorkItem else { return }
        
        if self.micInputProviderDelay > DispatchTime.now() {
            DispatchQueue.global().asyncAfter(deadline: self.micInputProviderDelay, execute: startMicWorkItem)
        } else {
            DispatchQueue.global().async(execute: startMicWorkItem)
        }
    }
    
    func stopListening() {
        if keywordDetector.state == .active {
            keywordDetector.stop()
            state = .cancelled
        }
        
        stopMicInputProvider()
        asrAgent.stopRecognition()
    }
    
    func startMicInputProvider(requestingFocus: Bool, completion: @escaping (EndedUp<Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] isGranted in
                guard let self = self else { return }
                guard isGranted else {
                    log.error("Record permission denied")
                    completion(.failure(SpeechRecognizerAggregatorError.micPermissionNotGranted))
                    return
                }
                
                self.micQueue.async { [weak self] in
                    guard let self = self else { return }
                    guard self.micInputProvider.isRunning == false else {
                        completion(.success)
                        return
                    }
                    
                    do {
                        try self.micInputProvider.start()
                        completion(.success)
                    } catch {
                        log.error(error)
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func stopMicInputProvider() {
        micQueue.async { [weak self] in
            self?.startMicWorkItem?.cancel()
            self?.micInputProvider.stop()
        }
    }
}

// MARK: - MicInputProviderDelegate

extension SpeechRecognizerAggregator: MicInputProviderDelegate {
    public func micInputProviderDidReceive(buffer: AVAudioPCMBuffer) {
        if keywordDetector.state == .active {
            keywordDetector.putAudioBuffer(buffer: buffer)
        }
        
        if [.listening(), .recognizing].contains(asrAgent.asrState) {
            asrAgent.putAudioBuffer(buffer: buffer)
        }
    }
    
    public func audioEngineConfigurationChanged() {
        // Nothing to do
    }
}

// MARK: - KeywordDetectorDelegate

extension SpeechRecognizerAggregator: KeywordDetectorDelegate {
    public func keywordDetectorDidDetect(keyword: String?, data: Data, start: Int, end: Int, detection: Int) {
        state = .wakeup(initiator: .wakeUpWord(keyword: keyword, data: data, start: start, end: end, detection: detection))
        
        asrAgent.startRecognition(initiator: .wakeUpWord(
            keyword: keyword,
            data: data,
            start: start,
            end: end,
            detection: detection
        ))
    }
    
    public func keywordDetectorStateDidChange(_ state: KeywordDetectorState) {
        if let state = SpeechRecognizerAggregatorState(state) {
            self.state = state
        }
    }
    
    public func keywordDetectorDidError(_ error: Error) {
        state = .error(error)
    }
}

// MARK: - ASR Observer

extension SpeechRecognizerAggregator {
    private func addAsrStateObserver() {
        if let asrStateObserver = asrStateObserver {
            notificationCenter.removeObserver(asrStateObserver)
        }
        
        // For use asr infinitely
        asrStateObserver = asrAgent.observe(NuguAgentNotification.ASR.State.self, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            
            if let state = SpeechRecognizerAggregatorState(notification.state) {
                self.state = state
            }
            
            switch notification.state {
            case .idle:
                if self.useKeywordDetector {
                    // if not restart here, keyword detector will be inactivated during tts speaking
                    self.keywordDetector.start()
                } else {
                    self.stopMicInputProvider()
                }
            case .listening:
                if self.useKeywordDetector {
                    self.keywordDetector.stop()
                }
            case .expectingSpeech:
                self.startMicInputProvider(requestingFocus: true) { [weak self] (endedUp) in
                    if case let .failure(error) = endedUp {
                        log.debug("startMicInputProvider failed: \(error)")
                        self?.asrAgent.stopRecognition()
                    }
                }
            default:
                break
            }
        }
    }
    
    private func addAsrResultObserver() {
        if let asrResultObserver = asrResultObserver {
            notificationCenter.removeObserver(asrResultObserver)
        }
        
        asrResultObserver = asrAgent.observe(NuguAgentNotification.ASR.Result.self, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            if let state = SpeechRecognizerAggregatorState(notification.result) {
                self.state = state
            }
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
