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
    private var epdWorkItem: DispatchWorkItem?
    private var engineHandle: EpdHandle?
    
    private var flushedLength: Int = 0
    private var flushLength: Int = 0
    private var inputStream: InputStream?
    
    #if DEBUG
    private var inputData = Data()
    private var outputData = Data()
    #endif
    
    public var state: State = .idle {
        didSet {
            if oldValue != state {
                delegate?.tycheEndPointDetectorEngineDidChange(state: state)
                log.debug("epd state changed: \(state)")
            }
        }
    }
    
    /// The flush time for reverb removal.
    public var flushTime: Int = 100
    
    public var epdFile: URL?
    
    public weak var delegate: TycheEndPointDetectorEngineDelegate?
    
    public func start(
        inputStream: InputStream,
        sampleRate: Double,
        timeout: Int,
        maxDuration: Int,
        pauseLength: Int
    ) {
        log.debug("")
        self.inputStream = inputStream
        epdWorkItem?.cancel()
        
        var workItem: DispatchWorkItem!
        workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            inputStream.delegate = self
            inputStream.schedule(in: .current, forMode: .default)
            inputStream.open()
            
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
                log.error("epd engine init error: \(error)")
                self.delegate?.tycheEndPointDetectorEngineDidChange(state: .error)
            }
            
            while workItem.isCancelled == false {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 1))
            }
            
            if self.engineHandle != nil {
                self.inputStream?.close()
                epdClientChannelRELEASE(self.engineHandle)
                self.engineHandle = nil
                self.state = .idle
            }
            
            workItem = nil
        }
        epdQueue.async(execute: workItem)
        epdWorkItem = workItem
    }
    
    public func stop() {
        log.debug("epd try to stop")
        epdWorkItem?.cancel()
        
        epdQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.inputStream?.close()
            epdClientChannelRELEASE(self.engineHandle)
            self.engineHandle = nil
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
        
        guard let epdFile = epdFile else { throw EndPointDetectorError.initFailed }
        
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
            guard let engineHandle = engineHandle else {
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
                    log.debug("epd input data to file :\(epdInputFileName)")
                    try inputData.write(to: epdInputFileName)
                    
                    let speexFileName = FileManager.default.urls(for: .documentDirectory,
                                                                 in: .userDomainMask)[0].appendingPathComponent("jade_marble_output.speex")
                    log.debug("speex data to file :\(speexFileName)")
                    try outputData.write(to: speexFileName)
                    
                    inputData.removeAll()
                    outputData.removeAll()
                } catch {
                    log.error("error: \(error)")
                }
            }
            #endif
            
            if [.idle, .listening, .start].contains(state) == false {
                stop()
            }
            
        case .endEncountered:
            log.debug("epd stream endEncountered")
            stop()

        default:
            break
        }
    }
}
