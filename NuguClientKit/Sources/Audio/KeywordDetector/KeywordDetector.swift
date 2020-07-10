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

import NuguCore
import KeenSense

public class KeywordDetector {
    private let detectorQueue = DispatchQueue(label: "com.sktelecom.romaine.keyword_detector")
    private var boundStreams: AudioBoundStreams?
    private let engine = TycheKeywordDetectorEngine()
    
    private let audioStream: AudioStreamable
    public weak var delegate: KeywordDetectorDelegate?
    
    public var state: KeywordDetectorState = .inactive {
        didSet {
            delegate?.keywordDetectorStateDidChange(state)
        }
    }
    
    // Must set `keywordSource` for using `KeywordDetector`
    public var keywordSource: KeywordSource? {
        didSet {
            detectorQueue.async { [weak self] in
                self?.engine.netFile = self?.keywordSource?.netFileUrl
                self?.engine.searchFile = self?.keywordSource?.searchFileUrl
            }
        }
    }
    
    public init(audioStream: AudioStreamable) {
        self.audioStream = audioStream
        engine.delegate = self
    }
    
    public func start() {
        log.debug("start")
        
        detectorQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.boundStreams?.stop()
            self.boundStreams = AudioBoundStreams(audioStreamReader: self.audioStream.makeAudioStreamReader())
            self.engine.start(inputStream: self.boundStreams!.input)
        }
    }
    
    public func stop() {
        log.debug("stop")
        
        detectorQueue.async { [weak self] in
            self?.boundStreams?.stop()
            self?.boundStreams = nil
            self?.engine.stop()
        }
    }
}

// MARK: - TycheKeywordDetectorEngineDelegate

extension KeywordDetector: TycheKeywordDetectorEngineDelegate {
    public func tycheKeywordDetectorEngineDidDetect(data: Data, start: Int, end: Int, detection: Int) {
        delegate?.keywordDetectorDidDetect(keyword: keywordSource?.keyword, data: data, start: start, end: end, detection: detection)
        stop()
    }
    
    public func tycheKeywordDetectorEngineDidError(_ error: Error) {
        delegate?.keywordDetectorDidError(error)
        stop()
    }
    
    public func tycheKeywordDetectorEngineDidChange(state: TycheKeywordDetectorEngine.State) {
        switch state {
        case .active:
            self.state = .active
        case .inactive:
            self.state = .inactive
        }
    }
}

// MARK: - ContextInfoDelegate

extension KeywordDetector: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: (ContextInfo?) -> Void) {
        guard let keyword = keywordSource?.keyword else {
            completion(nil)
            return
        }
        completion(ContextInfo(contextType: .client, name: "wakeupWord", payload: keyword))
    }
}
