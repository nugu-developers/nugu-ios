//
//  TycheEpd.swift
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

import NattyLog

public class TycheEpd: NSObject {
    public var state: TycheEpdState = .idle {
        didSet {
            if oldValue != state {
                delegate?.endPointDetectorStateChanged(state: state)
                log.debug("epd state changed: \(state)")
            }
        }
    }
    
    public weak var delegate: TycheEpdDelegate?
    
    /// The flush time for reverb removal.
    public var flushTime: Int = 100
    
    private var epdHandle: EpdHandle?
    private let epdQueue = DispatchQueue(label: "com.sktelecom.romaine.end_point_detector")
    private var epdWorkItem: DispatchWorkItem?
    public var epdFile: URL?
    
    var flushedLength: Int = 0
    var flushLength: Int = 0
    var inputStream: InputStream?
    
    #if DEBUG
    private var inputData = Data()
    private var outputData = Data()
    #endif
    
    public func start(inputStream: InputStream,
                      sampleRate: Double,
                      timeout: Int,
                      maxDuration: Int,
                      pauseLength: Int) throws {
        guard [.listening, .start].contains(state) == false else { return }
        
        do {
            try initDetectorEngine(sampleRate: sampleRate,
                                   timeout: timeout,
                                   maxDuration: maxDuration,
                                   pauseLength: pauseLength)
        } catch {
            log.error("epd engine init error: \(error)")
            throw error
        }
        
        state = .listening
        self.inputStream = inputStream
        flushedLength = 0
        flushLength = Int((Double(flushTime) * sampleRate) / 1000)
        
        epdWorkItem?.cancel()
        epdWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            inputStream.delegate = self
            inputStream.schedule(in: .current, forMode: .default)
            inputStream.open()
            
            while RunLoop.current.run(mode: .default, before: .distantFuture) && self.epdWorkItem?.isCancelled == false {}
        }
        epdQueue.async(execute: epdWorkItem!)
    }
    
    public func stop() {
        epdWorkItem?.cancel()
        
        epdQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.inputStream?.close()
            epdClientChannelRELEASE(self.epdHandle)
            self.epdHandle = nil
            self.state = .idle
        }
    }
    
    private func initDetectorEngine(sampleRate: Double,
                                    timeout: Int,
                                    maxDuration: Int,
                                    pauseLength: Int) throws {
        if epdHandle != nil {
            epdClientChannelRELEASE(epdHandle)
        }
        
        guard let epdFile = epdFile else { throw EndPointDetectorError.initFailed }
        
        try epdFile.path.withCString { (cstringEpdFile) -> Void in
            guard let epdHandle = epdClientChannelSTART(cstringEpdFile,
                                                        myint(sampleRate),
                                                        myint(EndPointDetectorConst.inputStreamType.rawValue),
                                                        myint(EndPointDetectorConst.outputStreamType.rawValue),
                                                        1,
                                                        myint(maxDuration),
                                                        myint(timeout),
                                                        myint(pauseLength)) else {
                                                            throw EndPointDetectorError.initFailed
            }

            self.epdHandle = epdHandle
        }
    }
}

extension TycheEpd: StreamDelegate {
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard let inputStream = aStream as? InputStream else { return }

        switch eventCode {
        case .hasBytesAvailable:
            let inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(4096))
            let inputLength = inputStream.read(inputBuffer, maxLength: 4096)
            
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
                
                return epdClientChannelRUN(epdHandle, ptrPcmData + adjustLength, myint((UInt32(inputLength)/2 - UInt32(adjustLength))*2), 0)
            }
            
            guard 0 <= engineState else { return }
            
            #if DEBUG
            inputData.append(inputBuffer, count: inputLength)
            #endif
            
            let length = epdClientChannelGetOutputDataSize(epdHandle)
            if 0 < length {
                let detectedBytes = UnsafeMutablePointer<Int8>.allocate(capacity: Int(length))
                let result = epdClientChannelGetOutputData(epdHandle, detectedBytes, length)
                if 0 < result {
                    let detectedData = Data(bytes: detectedBytes, count: Int(result))
                    delegate?.endPointDetectorSpeechDataExtracted(speechData: detectedData)
                    
                    #if DEBUG
                    outputData.append(detectedData)
                    #endif
                }
            }
            
            state = TycheEpdState(engineState: engineState)
            
            #if DEBUG
            if state == .end {
                do {
                    let epdInputFileName = FileManager.default.urls(for: .documentDirectory,
                                                                    in: .userDomainMask)[0].appendingPathComponent("jade_marble_input.raw")
                    log.debug("epd input data to file :\(epdInputFileName)")
                    try inputData.write(to: epdInputFileName)
                    
                    let speexFileName = FileManager.default.urls(for: .documentDirectory,
                                                                 in: .userDomainMask)[0].appendingPathComponent("jade_marble_output.raw")
                    log.debug("speex data to file :\(speexFileName)")
                    try outputData.write(to: speexFileName)
                } catch {
                    log.debug(error)
                }
            }
            #endif
            
            if [.idle, .listening, .start].contains(state) == false {
                inputStream.close()
                state = .idle
            }
            
        case .endEncountered:
            stop()

        default:
            break
        }
    }
}
