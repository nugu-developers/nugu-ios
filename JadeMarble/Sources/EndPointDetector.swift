//
//  EndPointDetector.swift
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

import NuguInterface 
import NattyLog

public class EndPointDetector: EndPointDetectable {
    public var state: EndPointDetectorState = .idle {
        didSet {
            if oldValue != state {
                delegate?.endPointDetectorStateChanged(state: state)
                log.debug("epd state changed: \(self.state)")
            }
        }
    }
    
    public weak var delegate: EndPointDetectorDelegate?
    
    /// The flush time for reverb removal.
    public var flushTime: Int = 100
    
    private var epdHandle: EpdHandle?
    private let epdQueue = DispatchQueue(label: "com.sktelecom.romaine.end_point_detector")
    private var epdWorkItem: DispatchWorkItem?
    public var epdFile: URL?
    
    #if DEBUG
    private var inputData = Data()
    private var outputData = Data()
    #endif
    
    public init() {}
    
    public func start(inputStream: AudioStreamReadable,
                      sampleRate: Double,
                      timeout: Int,
                      maxDuration: Int,
                      pauseLength: Int) throws {
        epdWorkItem?.cancel()
        epdWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.initDetectorEngine(sampleRate: sampleRate,
                                            timeout: timeout,
                                            maxDuration: maxDuration,
                                            pauseLength: pauseLength)
                self.state = .listening
            } catch {
                self.state = .idle
                self.delegate?.endPointDetectorDidError()
                log.error("epd engine init error: \(error)")
                return
            }
            
            var flushedLength: Int = 0
            let flushLength: Int = Int((Double(self.flushTime) * sampleRate) / 1000)
            let processAudioGroup = DispatchGroup()

            repeat {
                processAudioGroup.enter()
                inputStream.read { [weak self] (result) in
                    guard let self = self else { return }

                    guard case let .success(pcmBuffer) = result else {
                        self.state = .idle
                        processAudioGroup.leave()
                        return
                    }
                    
                    guard let ptrPcmData = pcmBuffer.int16ChannelData?.pointee else {
                        processAudioGroup.leave()
                        return
                    }

                    // Calculate flusehd audio frame length.
                    var adjustLength = 0
                    if flushedLength + Int(pcmBuffer.frameLength) <= flushLength {
                        flushedLength += Int(pcmBuffer.frameLength)
                        processAudioGroup.leave()
                        return
                    } else if flushedLength < flushLength {
                        flushedLength += Int(pcmBuffer.frameLength)
                        adjustLength = Int(pcmBuffer.frameLength) - (flushedLength - flushLength)
                    }
                    
                    let result = epdClientChannelRUN(self.epdHandle, ptrPcmData + adjustLength, myint((pcmBuffer.frameLength - UInt32(adjustLength))*2), 0)
                    
                    #if DEBUG
                    if let channelData = pcmBuffer.int16ChannelData?.pointee {
                        self.inputData.append(Data(bytes: channelData, count: Int(pcmBuffer.frameLength)*2))
                    }
                    #endif

                    let length = epdClientChannelGetOutputDataSize(self.epdHandle)
                    if 0 < length {
                        let detectedBytes = UnsafeMutablePointer<Int8>.allocate(capacity: Int(length))
                        let result = epdClientChannelGetOutputData(self.epdHandle, detectedBytes, length)
                        if 0 < result {
                            let detectedData = Data(bytes: detectedBytes, count: Int(result))
                            self.delegate?.endPointDetectorSpeechDataExtracted(speechData: detectedData)
                            
                            #if DEBUG
                            self.outputData.append(detectedData)
                            #endif
                        }
                    }
                    
                    self.state = EndPointDetectorState(tycheValue: result)
                    
                    #if DEBUG
                    if self.state == .end {
                        do {
                            let epdInputFileName = FileManager.default.urls(for: .documentDirectory,
                                                                            in: .userDomainMask)[0].appendingPathComponent("jade_marble_input.raw")
                            log.debug("epd input data to file :\(epdInputFileName)")
                            try self.inputData.write(to: epdInputFileName)
                            
                            let speexFileName = FileManager.default.urls(for: .documentDirectory,
                                                                         in: .userDomainMask)[0].appendingPathComponent("jade_marble_output.raw")
                            log.debug("speex data to file :\(speexFileName)")
                            try self.outputData.write(to: speexFileName)
                        } catch {
                            log.debug(error)
                        }
                    }
                    #endif
                    
                    processAudioGroup.leave()
                }
                
                processAudioGroup.wait()
                
                guard self.epdWorkItem?.isCancelled == false else {
                    self.state = .idle
                    return
                }
            } while [.listening, .start].contains(self.state)
            
            self.epdWorkItem = nil
        }
        
        epdQueue.async(execute: epdWorkItem!)
    }
    
    public func stop() {
        epdWorkItem?.cancel()
        epdWorkItem = nil
        
        epdQueue.async { [weak self] in
            guard let self = self else { return }
            
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
            epdClientChannelRELEASE(self.epdHandle)
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
