//
//  EndPointDetector.swift
//  NuguClientKit
//
//  Created by childc on 2019/11/07.
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
import JadeMarble

public class EndPointDetector: EndPointDetectable {
    private let engine = TycheEndPointDetectorEngine()
    private var boundStreams: BoundStreams?
    public weak var delegate: EndPointDetectorDelegate?
    
    public var state: EndPointDetectorState = .idle {
        didSet {
            delegate?.endPointDetectorStateChanged(state)
        }
    }
    
    public var epdFile: URL? {
        didSet {
            engine.epdFile = epdFile
        }
    }
    
    public init() {
        engine.delegate = self
    }
    
    public func start(
        inputStream: AudioStreamReadable,
        sampleRate: Double,
        timeout: Int,
        maxDuration: Int,
        pauseLength: Int
    ) {
        boundStreams?.stop()
        boundStreams = BoundStreams(buffer: inputStream)
        engine.start(
            inputStream: boundStreams!.input,
            sampleRate: sampleRate,
            timeout: timeout,
            maxDuration: maxDuration,
            pauseLength: pauseLength
        )
    }
    
    public func stop() {
        boundStreams?.stop()
        engine.stop()
    }
}

extension EndPointDetector: TycheEndPointDetectorEngineDelegate {
    public func tycheEndPointDetectorEngineDidChange(state: TycheEndPointDetectorEngine.State) {
        switch state {
        case .idle:
            self.state = .idle
        case .listening:
            self.state = .listening
        case .start:
            self.state = .start
        case .end:
            self.state = .end
        case .finish:
            self.state = .finish
        case .reachToMaxLength:
            self.state = .reachToMaxLength
        case .timeout:
            self.state = .timeout
        case .error:
            delegate?.endPointDetectorDidError()
        default:
            self.state = .unknown
        }
    }
    
    public func tycheEndPointDetectorEngineDidExtract(speechData: Data) {
        delegate?.endPointDetectorSpeechDataExtracted(speechData: speechData)
    }
}
