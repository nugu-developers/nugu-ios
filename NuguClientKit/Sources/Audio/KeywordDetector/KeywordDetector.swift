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

/// <#Description#>
public class KeywordDetector {
    private let engine = TycheKeywordDetectorEngine()
    /// <#Description#>
    public weak var delegate: KeywordDetectorDelegate?
    private let contextManager: ContextManageable
    private let kwdQueue = DispatchQueue(label: "com.sktelecom.romaine.keyword_detector_wrapper")
    
    /// <#Description#>
    private(set) public var state: KeywordDetectorState = .inactive {
        didSet {
            delegate?.keywordDetectorStateDidChange(state)
        }
    }
    
    private var internalKeywordSource: KeywordSource? = nil {
        didSet {
            log.debug("set keyword source")
            engine.setSource(netFilePath: internalKeywordSource?.netFileUrl.path, searchFilePath: internalKeywordSource?.searchFileUrl.path)
        }
    }
    
    /// Must set `keywordSource` for using `KeywordDetector`
    public var keywordSource: KeywordSource? {
        get {
            return kwdQueue.sync {
                return internalKeywordSource
            }
        }
        
        set {
            kwdQueue.sync {
                internalKeywordSource = newValue
            }
        }
    }
    
    /// <#Description#>
    public init(contextManager: ContextManageable) {
        self.contextManager = contextManager
        engine.delegate = self
        
        contextManager.addProvider(contextInfo)
    }
    
    deinit {
        contextManager.removeProvider(contextInfo)
    }
    
    public lazy var contextInfo: ProvideContextInfo = { [weak self] completion in
        guard let self = self else { return }
        
        guard let keyword = self.keywordSource?.keyword else {
            completion(nil)
            return
        }
        completion(ContextInfo(contextType: .client, name: "wakeupWord", payload: keyword))
    }
    
    /// <#Description#>
    public func start() {
        log.debug("start")
        engine.start()
    }
    
    /// <#Description#>
    /// - Parameter buffer: <#buffer description#>
    public func putAudioBuffer(buffer: AVAudioPCMBuffer) {
        guard let pcmBuffer: AVAudioPCMBuffer = buffer.copy() as? AVAudioPCMBuffer else {
            log.warning("copy buffer failed")
            return
        }

        engine.putAudioBuffer(buffer: pcmBuffer)
    }
    
    /// <#Description#>
    public func stop() {
        engine.stop()
    }
}

// MARK: - TycheKeywordDetectorEngineDelegate

/// :nodoc:
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
