//
//  KeyWordDector.swift
//  KeenSense
//
//  Created by DCs-OfficeMBP on 26/04/2019.
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

import NuguInterface

/**
 Default key word detector of NUGU service.
 
 When the key word detected, you can take PCM data of user's voice.
 so you can do Speaker Recognition, enhance the recognizing rate and so on using this data.
 */
public class KeyWordDetector {
    private var engineHandle: WakeupHandle?
    public var netFile: URL?
    public var searchFile: URL?
    private let detectQueue = DispatchQueue(label: "com.sktelecom.romaine.wake_up_detector_queue")
    private var detectItem: DispatchWorkItem?

    public var detectedData: DetectedData? // User's voice data of speaking key word.
    public var audioStream: AudioStreamable!
    public weak var delegate: WakeUpDetectorDelegate?
    public var state: WakeUpDetectorState = .inactive {
        didSet {
            if oldValue != state {
                delegate?.wakeUpDetectorStateDidChange(state)
                log.debug("kwd state changed: \(state)")
            }
        }
    }
    
    /**
     Window buffer for user's voice. This will help extract certain section of speaking key word
     */
    private var detectingData = ShiftingData(capacity: Int(KeyWordDetectorConst.sampleRate*5*2))
    
    public init() {}
    
    deinit {
        if state == .active {
            stop()
        }
    }
}

// MARK: - WakeUpDetectable

extension KeyWordDetector: WakeUpDetectable {
    /**
     Start Key Word Detection.
     */
    public func start() {
        if let detectItem = detectItem {
            detectItem.cancel()
        }
        
        // Detecting loop can be cancelled anytime. so we use DispatchWorkItem.
        detectItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            do {
                try self.initTriggerEngine()
            } catch {
                self.state = .inactive
                self.delegate?.wakeUpDetectorDidError(error)
                log.debug("kwd error: \(error)")
                return
            }

            let inputStream = self.audioStream.makeAudioStreamReader()
            self.state = .active
            let detectGroup = DispatchGroup()
            
            #if DEBUG
            let filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("detecting.raw")
            #endif
            
            var detected = false
            repeat {
                detectGroup.enter()
                inputStream.read { (result) in
                    guard case let .success(buffer) = result else {
                        log.info("writer won't work any longer.")
                        self.state = .inactive
                        self.delegate?.wakeUpDetectorDidError(KeyWordDetectorError.noDataAvailable)
                        detectGroup.leave()
                        return
                    }
                    
                    /** once kwd engine initialized, There are no situation of occuring error in processAudioBuffer.
                     The engine won't be deinitialized before detecting loop stopped.
                     and AudioBuffer's Init16 channel data should be filled with data.
                     these two conditions are prevented their initialization. But, we should care about Optional Binding convention.
                     - seeAlso: processAudioBuffer()
                     */
                    detected = (try? self.processAudioBuffer(buffer)) ?? false
                    detectGroup.leave()
                }
                
                detectGroup.wait()

                guard self.detectItem?.isCancelled == false else {
                    log.warning("detect task is cancelled..")
                    self.state = .inactive
                    
                    #if DEBUG
                    do {
                        try self.detectingData.write(to: filename)
                        log.debug("detecting filename: \(filename)")
                    } catch {
                        log.debug(error)
                    }
                    #endif
                    
                    return
                }
            } while detected == false && self.state == .active

            if detected {
                log.debug("detected.")
                self.state = .inactive
                self.delegate?.wakeUpDetectorDidDetect()
            }
            
            self.detectItem = nil
        }
        detectQueue.async(execute: detectItem!)
    }
    
    public func stop() {
        detectItem?.cancel()
        detectItem = nil
        
        detectQueue.async { [weak self] in
            guard let self = self else { return }

            if self.engineHandle != nil {
                log.debug("try engine destroy")
                Wakeup_Destroy(self.engineHandle)
                log.debug("engine is destroyed")
                self.engineHandle = nil
            }
        }
    }
}

// MARK: - Legacy Trigger Engine

extension KeyWordDetector {
    
    /**
     Initialize Key Word Detec engine.
     It needs certain files of Voice Recognition. But we wrap this and offer the simple API.
     Then only you have to do is making decision which key word you use.
     */
    private func initTriggerEngine() throws {
        if self.engineHandle != nil {
            Wakeup_Destroy(self.engineHandle)
        }
        
        guard let netFile = netFile,
            let searchFile = searchFile else {
                throw KeyWordDetectorError.initEngineFailed
        }
        
        try netFile.path.withCString { cstringNetFile -> Void in
            try searchFile.path.withCString({ cstringSearchFile -> Void in
                guard let wakeUpHandle = Wakeup_Create(cstringNetFile, cstringSearchFile, 0) else {
                    throw KeyWordDetectorError.initEngineFailed
                }
                self.engineHandle = wakeUpHandle
            })
        }
    }

    /**
     Pass the chunk of audio data to Key Word Detect engine.
     because The engine have own audio buffer, We don't care about fragment of audio.
     The engine will check Whole audio data passed contains key word or not.
     */
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) throws -> Bool {
        // These two conditions won't throw the error because of their initialization.
        // But we wnat follow Optional Binding convention.
        guard let engineHandle = engineHandle else { throw KeyWordDetectorError.initEngineFailed }
        
        guard let ptrPcmData = buffer.int16ChannelData?.pointee else {
            throw KeyWordDetectorError.unsupportedAudioFormat
        }
        
        if let ptrChannelData = buffer.int16ChannelData?.pointee {
            let channelData = Data(bytes: ptrChannelData, count: Int(buffer.frameLength)*2)
            self.detectingData.append(channelData)
        }
        
        guard Wakeup_PutAudio(engineHandle, ptrPcmData, Int32(buffer.frameLength)) == 1 else {
            return false
        }

        extractDetectedData()
        return true
    }
}

// MARK: - ETC
extension KeyWordDetector {
    private func extractDetectedData() {
        let startTime = Int(Wakeup_GetStartTime(engineHandle))
        let endTime = Int(Wakeup_GetEndTime(engineHandle))
        let paddingTime = Int(Wakeup_GetDelayTime(engineHandle))
        
        // convert time to frame count
        let startIndex = (startTime * KeyWordDetectorConst.sampleRate * 2) / 1000
        let endIndex = (endTime * KeyWordDetectorConst.sampleRate * 2) / 1000
        let paddingSize = (paddingTime * KeyWordDetectorConst.sampleRate * 2) / 1000
        log.debug("startTime: \(startTime),(\(startIndex)), endTime: \(endTime),(\(endIndex)), paddingTime: \(paddingTime)")
        
        let size = (endIndex - startIndex) + paddingSize
        let detectedRange = (detectingData.count - size)..<detectingData.count
        detectedData = DetectedData(data: detectingData.subdata(in: detectedRange), padding: paddingSize)
        
        // reset buffers
        detectingData.removeAll()
        
        #if DEBUG
        let filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("detected.raw")
        do {
            log.debug(filename)
            if let detectedData = detectedData {
                try detectedData.data.write(to: filename)
            }
        } catch {
            log.debug(error)
        }
        #endif
    }
}
