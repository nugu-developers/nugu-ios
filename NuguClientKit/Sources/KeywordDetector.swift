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

import NuguInterface
import KeenSense

public class KeywordDetector: WakeUpDetectable {
    public var audioStream: AudioStreamable!

    private var boundStreams: BoundStreams?
    private let engine = TycheKeywordDetectorEngine()
    public weak var delegate: WakeUpDetectorDelegate?
    
    public var state: WakeUpDetectorState = .inactive {
        didSet {
            delegate?.wakeUpDetectorStateDidChange(state)
        }
    }
    
    public var netFilePath: URL? {
        get {
            engine.netFile
        }
        set {
            engine.netFile = newValue
        }
    }
    
    public var searchFilePath: URL? {
        get {
            engine.searchFile
        }
        set {
            engine.searchFile = newValue
        }
    }
    
    public init() {
        engine.delegate = self
    }
    
    public func start() {
        boundStreams?.stop()
        boundStreams = BoundStreams(buffer: audioStream.makeAudioStreamReader())
        engine.start(inputStream: boundStreams!.input)
    }
    
    public func stop() {
        boundStreams?.stop()
        engine.stop()
    }
}

// MARK: - TycheKeywordDetectorEngineDelegate

extension KeywordDetector: TycheKeywordDetectorEngineDelegate {
    public func tycheKeywordDetectorEngineDidDetect() {
        delegate?.wakeUpDetectorDidDetect()
    }
    
    public func tycheKeywordDetectorEngineDidError(_ error: Error) {
        delegate?.wakeUpDetectorDidError(error)
    }
    
    public func tycheKeywordDetectorEngineDidChange(_ state: TycheKeywordDetectorEngine.State) {
        switch state {
        case .active:
            delegate?.wakeUpDetectorStateDidChange(.active)
        case .inactive:
            delegate?.wakeUpDetectorStateDidChange(.inactive)
        }
    }
}
