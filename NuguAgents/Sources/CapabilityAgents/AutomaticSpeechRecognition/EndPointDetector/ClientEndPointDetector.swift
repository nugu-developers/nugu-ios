//
//  ClientEndPointDetector.swift
//  NuguAgents
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

import NuguCore
import JadeMarble

class ClientEndPointDetector: EndPointDetectable {
    public weak var delegate: EndPointDetectorDelegate?
    
    private let asrOptions: ASROptions
    private var engine: TycheEndPointDetectorEngine!
    
    private var boundStreams: AudioBoundStreams?
    
    private var state: EndPointDetectorState = .idle {
        didSet {
            delegate?.endPointDetectorStateChanged(state)
        }
    }
    
    public init(asrOptions: ASROptions, epdFile: URL) {
        self.asrOptions = asrOptions
        
        engine = TycheEndPointDetectorEngine(epdFile: epdFile)
        engine.delegate = self
    }
    
    func start(audioStreamReader: AudioStreamReadable) {
        boundStreams?.stop()
        boundStreams = AudioBoundStreams(audioStreamReader: audioStreamReader)
        engine.start(
            inputStream: boundStreams!.input,
            sampleRate: asrOptions.sampleRate,
            timeout: asrOptions.timeout.truncatedSeconds,
            maxDuration: asrOptions.maxDuration.truncatedSeconds,
            pauseLength: asrOptions.pauseLength.truncatedMilliSeconds
        )
    }
    
    public func stop() {
        boundStreams?.stop()
        engine.stop()
    }
    
    func handleNotifyResult(_ state: ASRNotifyResult.State) {
        // do nothing
    }
}

extension ClientEndPointDetector: TycheEndPointDetectorEngineDelegate {
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
