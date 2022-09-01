//
//  KeywordDetector.swift
//  NuguClientKit
//
//  Created by childc on 2019/11/11.
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

import NuguUtils
import NuguCore
import KeenSense

public typealias Keyword = KeenSense.Keyword

/// <#Description#>
public class KeywordDetector: ContextInfoProvidable {
    private let engine = TycheKeywordDetectorEngine()
    /// KeywordDetector delegate
    public weak var delegate: KeywordDetectorDelegate?
    private let contextManager: ContextManageable
    
    /// Keyword detector state
    private(set) public var state: KeywordDetectorState = .inactive {
        didSet {
            delegate?.keywordDetectorStateDidChange(state)
        }
    }
    
    /// Must set `keywordSource` for using `KeywordDetector`
    @Atomic public var keyword: Keyword = .aria {
        didSet {
            log.debug("set keyword: \(keyword)")
            engine.keyword = keyword
        }
    }
    
    // Observers
    let observerQueue = DispatchQueue(label: "com.sktelecom.romaine.keensense.tyche_observers")
    var tycheKeywordDetectorStateObserver: Any?
    var tycheKeywordDetectorErrorObserver: Any?
    var tycheKeywordDetectorDetectedInfoObserver: Any?
    
    public init(contextManager: ContextManageable) {
        self.contextManager = contextManager
        contextManager.addProvider(contextInfoProvider)
        addObservers()
    }
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
        removeObservers()
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        completion(ContextInfo(contextType: .client, name: "wakeupWord", payload: self.keyword.description))
    }
    
    /// Start keyword detection.
    public func start() {
        log.debug("start")
        engine.start()
    }
    
    /// Put  pcm data to the engine
    /// - Parameter buffer: PCM buffer contained voice data
    public func putAudioBuffer(buffer: AVAudioPCMBuffer) {
        guard let pcmBuffer: AVAudioPCMBuffer = buffer.copy() as? AVAudioPCMBuffer else {
            log.warning("copy buffer failed")
            return
        }

        engine.putAudioBuffer(buffer: pcmBuffer)
    }
    
    /// Stop keyword detection.
    public func stop() {
        engine.stop()
    }
}

// MARK: - TycheKeywordDetector Observers

extension KeywordDetector {
    func addObservers() {
        tycheKeywordDetectorStateObserver = engine.observe(TycheKeywordDetectorEngine.State.self, queue: nil) { [weak self] notification in
            self?.observerQueue.async { [weak self] in
                log.debug("tyche keyword detector engine state changed to \(notification)")
                self?.state = notification.keywordDetectorState
            }
        }
        
        tycheKeywordDetectorErrorObserver = engine.observe(TycheKeywordDetectorEngine.KeywordDetectorError.self, queue: nil) { [weak self] notification in
            self?.observerQueue.async { [weak self] in
                log.debug("tyche keyword detector engine error: \(notification)")
                
                self?.delegate?.keywordDetectorDidError(notification)
                self?.stop()
            }
        }
        
        tycheKeywordDetectorDetectedInfoObserver = engine.observe(TycheKeywordDetectorEngine.DetectedInfo.self, queue: nil) { [weak self] notification in
            self?.observerQueue.async { [weak self] in
                guard let self = self else { return }
                log.debug("tyche keyword detector engine detected: \(notification))")
                
                self.delegate?.keywordDetectorDidDetect(keyword: self.keyword.description, data: notification.data, start: notification.start, end: notification.end, detection: notification.detection)
                self.stop()
            }
        }
    }
    
    func removeObservers() {
        if let tycheKeywordDetectorStateObserver = tycheKeywordDetectorStateObserver {
            NotificationCenter.default.removeObserver(tycheKeywordDetectorStateObserver)
            self.tycheKeywordDetectorStateObserver = nil
        }
        
        if let tycheKeywordDetectorErrorObserver = tycheKeywordDetectorErrorObserver {
            NotificationCenter.default.removeObserver(tycheKeywordDetectorErrorObserver)
            self.tycheKeywordDetectorErrorObserver = nil
        }
        
        if let tycheKeywordDetectorDetectedInfoObserver = tycheKeywordDetectorDetectedInfoObserver {
            NotificationCenter.default.removeObserver(tycheKeywordDetectorDetectedInfoObserver)
            self.tycheKeywordDetectorDetectedInfoObserver = nil
        }
    }
}

// MARK: - TycheKeywordDetectorEngine.State transform

extension TycheKeywordDetectorEngine.State {
    var keywordDetectorState: KeywordDetectorState {
        switch self {
        case .active:
            return .active
        case .inactive:
            return .inactive
        }
    }
}
