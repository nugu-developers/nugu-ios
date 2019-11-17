//
//  TycheKwd.swift
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

/**
 Default key word detector of NUGU service.
 
 When the key word detected, you can take PCM data of user's voice.
 so you can do Speaker Recognition, enhance the recognizing rate and so on using this data.
 */
public class TycheKwd: NSObject {
    private var engineHandle: WakeupHandle?
    public var netFile: URL?
    public var searchFile: URL?
    private let kwdQueue = DispatchQueue(label: "com.sktelecom.romaine.key_word_detector")
    private var kwdWorkItem: DispatchWorkItem?

    public var detectedData: DetectedData? // User's voice data of speaking key word.
    public var inputStream: InputStream?
    public weak var delegate: TycheKwdDelegate?
    public var state: KeyWordDetectorState = .inactive {
        didSet {
            if oldValue != state {
                delegate?.keyWordDetectorStateDidChange(state)
                log.debug("kwd state changed: \(state)")
            }
        }
    }
    
    /**
     Window buffer for user's voice. This will help extract certain section of speaking key word
     */
    private var detectingData = ShiftingData(capacity: Int(KeyWordDetectorConst.sampleRate*5*2))
    
    #if DEBUG
    let filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("detecting.raw")
    #endif
    
    deinit {
        if state == .active {
            stop()
        }
    }
    
    /**
     Start Key Word Detection.
     */
    public func start(inputStream: InputStream) {
        log.debug("kwd try to start")
        self.inputStream = inputStream
        kwdWorkItem?.cancel()
        
        var workItem: DispatchWorkItem!
        workItem = DispatchWorkItem { [weak self] in
            log.debug("kwd task start")
            
            guard let self = self else { return }
            log.debug("kwd task is eligible for running ")
            
            do {
                try self.initTriggerEngine()
            } catch {
                self.state = .inactive
                self.delegate?.keyWordDetectorDidError(error)
                log.debug("kwd error: \(error)")
            }
            
            self.state = .active
            
            inputStream.delegate = self
            inputStream.schedule(in: .current, forMode: .default)
            inputStream.open()
            
            while workItem.isCancelled == false {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 1))
            }
            
            log.debug("kwd task is going to stop")
            if self.engineHandle != nil {
                log.debug("kwd task stops engine and stream.")
                self.inputStream?.close()
                Wakeup_Destroy(self.engineHandle)
                self.engineHandle = nil
                self.state = .inactive
            }
            
            workItem = nil
        }
        kwdQueue.async(execute: workItem!)
        kwdWorkItem = workItem
        log.debug("kwd tried to start")
    }
    
    public func stop() {
        log.debug("kwd try to stop")
        kwdWorkItem?.cancel()
        
        kwdQueue.async { [weak self] in
            log.debug("kwd stop task is started")
            guard let self = self else { return }

            log.debug("kwd stop task stops engine and stream.")
            self.inputStream?.close()
            Wakeup_Destroy(self.engineHandle)
            self.engineHandle = nil
            self.state = .inactive
        }
    }
}

// MARK: - Legacy Trigger Engine

extension TycheKwd {
    
    /**
     Initialize Key Word Detec engine.
     It needs certain files of Voice Recognition. But we wrap this and offer the simple API.
     Then only you have to do is making decision which key word you use.
     */
    private func initTriggerEngine() throws {
        if engineHandle != nil {
            Wakeup_Destroy(engineHandle)
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
                engineHandle = wakeUpHandle
            })
        }
    }
}

// MARK: - ETC
extension TycheKwd {
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

extension TycheKwd: StreamDelegate {
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard let inputStream = aStream as? InputStream,
            inputStream == self.inputStream else { return }
        
        switch eventCode {
        case .hasBytesAvailable:
            let inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(4096))
            let inputLength = inputStream.read(inputBuffer, maxLength: 4096)
            guard 0 < inputLength else { return }

            detectingData.append(Data(bytes: inputBuffer, count: inputLength))
            
            let isDetected = inputBuffer.withMemoryRebound(to: Int16.self, capacity: inputLength/2) { (ptrPcmData) -> Bool in
                return Wakeup_PutAudio(engineHandle, ptrPcmData, Int32(inputLength/2)) == 1
            }
            
            if isDetected {
                log.debug("kwd hasBytesAvailable detected")
                stop()

                extractDetectedData()
                self.delegate?.keyWordDetectorDidDetect()
            }
            
        case .endEncountered:
            log.debug("kwd stream endEncountered")
            stop()
            
        default:
            break
        }
    }
}
