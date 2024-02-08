//
//  TycheEndPointDetectorEngine.swift
//  JadeMarble
//
//  Created by DCs-OfficeMBP on 15/05/2019.
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

import TycheSDK

public class TycheEndPointDetectorEngine {
    private let epdQueue = DispatchQueue(label: "com.sktelecom.romaine.jademarble.tyche_end_point_detector")
    private var flushedLength: Int = 0
    private var flushLength: Int = 0
    private var engineHandle: EpdHandle?
    private var speexEncoder: SpeexEncoder?
    public weak var delegate: TycheEndPointDetectorEngineDelegate?
    
    #if DEBUG
    private var inputData = Data()
    private var outputData = Data()
    #endif
    
    /// The flush time for reverb removal.
    public var flushTime: Int = 100
    
    public var state: State = .idle {
        didSet {
            if oldValue != state {
                delegate?.tycheEndPointDetectorEngineDidChange(state: state)
                log.debug("state changed: \(state)")
            }
        }
    }
    
    public init() {}
    
    deinit {
        internalStop()
    }
    
    public func start(
        sampleRate: Double,
        timeout: Int,
        maxDuration: Int,
        pauseLength: Int
    ) {
        log.debug("engine try to start")
        
        epdQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.engineHandle != nil {
                // Release last components
                self.internalStop()
            }
            
             do {
                try self.initDetectorEngine(
                    sampleRate: sampleRate,
                    timeout: timeout,
                    maxDuration: maxDuration,
                    pauseLength: pauseLength
                )
                
                self.state = .listening
                self.flushedLength = 0
                self.flushLength = Int((Double(self.flushTime) * sampleRate) / 1000)
            } catch {
                self.state = .idle
                log.error("engine init error: \(error)")
                self.delegate?.tycheEndPointDetectorEngineDidChange(state: .error)
            }
        }
    }
    
    public func putAudioBuffer(buffer: AVAudioPCMBuffer) {
        epdQueue.async { [weak self] in
            guard let self = self else { return }
            guard let ptrPcmData = buffer.int16ChannelData?.pointee,
                0 < buffer.frameLength else {
                log.warning("There's no 16bit audio data.")
                return
            }

            let (engineState, inputData) = ptrPcmData.withMemoryRebound(to: UInt8.self, capacity: Int(buffer.frameLength * 2)) { (ptrData) -> (Int32, Data) in
                #if DEBUG
                self.inputData.append(ptrData, count: Int(buffer.frameLength) * 2)
                #endif
                let inputData = Data(bytes: ptrData, count: Int(buffer.frameLength) * 2)
                
                // Calculate flushed audio frame length.
                var adjustLength = 0
                if self.flushedLength + Int(buffer.frameLength) <= self.flushLength {
                    self.flushedLength += Int(buffer.frameLength)
                    return (-1, inputData)
                } else if self.flushedLength < self.flushLength {
                    self.flushedLength += Int(buffer.frameLength)
                    adjustLength = Int(buffer.frameLength) - (self.flushedLength - self.flushLength)
                }
                
                let engineState = epdClientChannelRUN(
                    self.engineHandle,
                    ptrData,
                    myint(UInt32(buffer.frameLength) - UInt32(adjustLength)) * 2, // data length is double of frame length, because It is 16bit audio data.
                    0
                )
                
                return (engineState, inputData)
            }
            guard 0 <= engineState, let speexEncoder else { return }
            
            do {
                let speexData = try speexEncoder.encode(data: inputData)
                self.delegate?.tycheEndPointDetectorEngineDidExtract(speechData: speexData)
                #if DEBUG
                self.outputData.append(speexData)
                #endif
            } catch {
                log.error("Failed to speex encoding, error: \(error)")
            }
            
            self.state = TycheEndPointDetectorEngine.State(engineState: engineState)
            
            #if DEBUG
            if self.state == .end {
                do {
                    let epdInputFileName = FileManager.default.urls(for: .documentDirectory,
                                                                    in: .userDomainMask)[0].appendingPathComponent("jade_marble_input.raw")
                    log.debug("input data file :\(epdInputFileName)")
                    try self.inputData.write(to: epdInputFileName)
                    
                    let speexFileName = FileManager.default.urls(for: .documentDirectory,
                                                                 in: .userDomainMask)[0].appendingPathComponent("jade_marble_output.speex")
                    log.debug("speex data file :\(speexFileName)")
                    try self.outputData.write(to: speexFileName)
                    
                    self.inputData.removeAll()
                    self.outputData.removeAll()
                } catch {
                    log.debug(error)
                }
            }
            #endif
            
            if [.idle, .listening, .start].contains(self.state) == false {
                self.internalStop()
            }
        }
    }
    
    public func stop() {
        log.debug("try to stop")
        
        epdQueue.async { [weak self] in
            self?.internalStop()
        }
    }
    
    private func internalStop() {
        if engineHandle != nil {
            epdClientChannelRELEASE(engineHandle)
            engineHandle = nil
            log.debug("engine is destroyed")
        }
        
        speexEncoder = nil
        state = .idle
    }
    
    private func initDetectorEngine(
        sampleRate: Double,
        timeout: Int,
        maxDuration: Int,
        pauseLength: Int
    ) throws {
        if engineHandle != nil {
            epdClientChannelRELEASE(engineHandle)
        }
        
        #if DEPLOY_OTHER_PACKAGE_MANAGER
        let modelPath = Bundle(for: TycheEndPointDetectorEngine.self).url(forResource: "skt_epd_model", withExtension: "raw")!.path
        #else
        let modelPath = Bundle.module.url(forResource: "skt_epd_model", withExtension: "raw")!.path
        #endif
        
        let speexEncoder = SpeexEncoder(sampleRate: Int(sampleRate), inputType: EndPointDetectorConst.inputStreamType)
        self.speexEncoder = speexEncoder
        guard let epdHandle = epdClientChannelSTART(
            modelPath,
            myint(sampleRate),
            myint(EndPointDetectorConst.inputStreamType.rawValue),
            myint(EndPointDetectorConst.outputStreamType.rawValue),
            1,
            myint(maxDuration),
            myint(timeout),
            myint(pauseLength)
            ) else {
                throw EndPointDetectorError.initFailed
        }
        
        self.engineHandle = epdHandle
    }
}
