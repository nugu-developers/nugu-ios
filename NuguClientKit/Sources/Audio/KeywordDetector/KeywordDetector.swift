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
    private let engine = TycheKeywordDetectorEngine()
    public weak var delegate: KeywordDetectorDelegate?
    
    public var state: KeywordDetectorState = .inactive {
        didSet {
            delegate?.keywordDetectorStateDidChange(state)
        }
    }
    
    // Must set `keywordSource` for using `KeywordDetector`
    public var keywordSource: KeywordSource? {
        didSet {
            engine.netFilePath = keywordSource?.netFileUrl.path
            engine.searchFilePath = keywordSource?.searchFileUrl.path
        }
    }
    
    public init() {
        engine.delegate = self
    }
    
    public func start() {
        log.debug("start")
        engine.start()
    }
    
    public func putAudioBuffer(buffer: AVAudioPCMBuffer) {
        guard let pcmBuffer: AVAudioPCMBuffer = buffer.copy() as? AVAudioPCMBuffer else {
            log.warning("copy buffer failed")
            return
        }

        engine.putAudioBuffer(buffer: pcmBuffer)
    }
    
    public func stop() {
        engine.stop()
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
