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

public class TycheEndPointDetectorEngine: NSObject {
    private let epdQueue = DispatchQueue(label: "com.sktelecom.romaine.jademarble.tyche_end_point_detector")
    private let epdFile: URL
    private var flushedLength: Int = 0
    private var flushLength: Int = 0
    private var inputStream: InputStream?
    private var engineHandle: EpdHandle?
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
    
    public init(epdFile: URL) {
        self.epdFile = epdFile
    }
    
    public func start(
        inputStream: InputStream,
        sampleRate: Double,
        timeout: Int,
        maxDuration: Int,
        pauseLength: Int
    ) {
        log.debug("engine try to start")

        if [.closed, .notOpen].contains(inputStream.streamStatus) == false || engineHandle != nil {
            // Release last components
            stop()
        }
        
        self.inputStream = inputStream
        CFReadStreamSetDispatchQueue(inputStream, epdQueue)
        inputStream.delegate = self
        inputStream.open()
        
        epdQueue.async { [weak self] in
            guard let self = self else { return }
            
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
    
    public func stop() {
        log.debug("try to stop")

        if inputStream?.streamStatus != .closed {
            inputStream?.close()
            inputStream?.delegate = nil
            log.debug("bounded input stream is closed")
        }
        
        epdQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.engineHandle != nil {
                epdClientChannelRELEASE(self.engineHandle)
                self.engineHandle = nil
                log.debug("engine is destroyed")
            }

            self.state = .idle
        }
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
        
        try epdFile.path.withCString { [weak self] (cstringEpdFile) -> Void in
            guard let self = self else { return }
            
            guard let epdHandle = epdClientChannelSTART(
                cstringEpdFile,
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
}

extension TycheEndPointDetectorEngine: StreamDelegate {
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard let inputStream = aStream as? InputStream,
            inputStream == self.inputStream else { return }

        switch eventCode {
        case .hasBytesAvailable:
            guard engineHandle != nil else {
                stop()
                return
            }
            
            let inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(4096))
            defer { inputBuffer.deallocate() }
            
            let inputLength = inputStream.read(inputBuffer, maxLength: 4096)
            guard 0 < inputLength else { return }
            
            let engineState = inputBuffer.withMemoryRebound(to: Int16.self, capacity: inputLength/2) { (ptrPcmData) -> Int32 in
                // Calculate flusehd audio frame length.
                var adjustLength = 0
                if flushedLength + (inputLength/2) <= flushLength {
                    flushedLength += (inputLength/2)
                    return -1
                } else if flushedLength < flushLength {
                    flushedLength += (inputLength/2)
                    adjustLength = (inputLength/2) - (flushedLength - flushLength)
                }
                
                return epdClientChannelRUN(
                    engineHandle,
                    ptrPcmData + adjustLength,
                    myint((UInt32(inputLength)/2 - UInt32(adjustLength))*2),
                    0
                )
            }
            
            guard 0 <= engineState else { return }
            
            #if DEBUG
            inputData.append(inputBuffer, count: inputLength)
            #endif
            
            let length = epdClientChannelGetOutputDataSize(engineHandle)
            if 0 < length {
                let detectedBytes = UnsafeMutablePointer<Int8>.allocate(capacity: Int(length))
                defer { detectedBytes.deallocate() }
                
                let result = epdClientChannelGetOutputData(engineHandle, detectedBytes, length)
                if 0 < result {
                    let detectedData = Data(bytes: detectedBytes, count: Int(result))
                    delegate?.tycheEndPointDetectorEngineDidExtract(speechData: detectedData)
                    
                    #if DEBUG
                    outputData.append(detectedData)
                    #endif
                }
            }
            
            state = TycheEndPointDetectorEngine.State(engineState: engineState)
            
            #if DEBUG
            if state == .end {
                do {
                    let epdInputFileName = FileManager.default.urls(for: .documentDirectory,
                                                                    in: .userDomainMask)[0].appendingPathComponent("jade_marble_input.raw")
                    log.debug("input data file :\(epdInputFileName)")
                    try inputData.write(to: epdInputFileName)
                    
                    let speexFileName = FileManager.default.urls(for: .documentDirectory,
                                                                 in: .userDomainMask)[0].appendingPathComponent("jade_marble_output.speex")
                    log.debug("speex data file :\(speexFileName)")
                    try outputData.write(to: speexFileName)
                    
                    inputData.removeAll()
                    outputData.removeAll()
                } catch {
                    log.debug(error)
                }
            }
            #endif
            
            if [.idle, .listening, .start].contains(state) == false {
                stop()
            }
            
        case .endEncountered:
            log.debug("stream endEncountered")
            stop()

        default:
            break
        }
    }
}
