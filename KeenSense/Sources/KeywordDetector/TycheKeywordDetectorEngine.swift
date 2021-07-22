//
//  TycheKeywordDetectorEngine.swift
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

import NuguUtils
import TycheSDK

/**
 Default key word detector of NUGU service.
 
 When the key word detected, you can take PCM data of user's voice.
 so you can do Speaker Recognition, enhance the recognizing rate and so on using this data.
 */
public class TycheKeywordDetectorEngine: TypedNotifyable {
    private let kwdQueue = DispatchQueue(label: "com.sktelecom.romaine.keensense.tyche_key_word_detector")
    private var engineHandle: WakeupHandle?
    
    /// Window buffer for user's voice. This will help extract certain section of speaking keyword
    private var detectingData = ShiftingData(capacity: Int(KeywordDetectorConst.sampleRate*5*2))
    
    /// Tyche Keyword detector engine state
    public var state: TycheKeywordDetectorEngine.State = .inactive {
        didSet {
            if oldValue != state {
                log.debug("state changed: \(state)")
                post(state)
            }
        }
    }
    
    /// Keyword to detect
    public var keyword: Keyword {
        get {
            internalKeyword
        }
        
        set {
            kwdQueue.async { [weak self] in
                self?.internalKeyword = newValue
            }
        }
    }
    private var internalKeyword: Keyword = .aria
    
    #if DEBUG
    private let filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("detecting.raw")
    #endif
    
    public init() {}
    
    deinit {
        internalStop()
    }
    
    /**
     Start keyword Detection.
     */
    public func start() {
        log.debug("try to start")
        
        kwdQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.engineHandle != nil {
                // Release last components
                self.internalStop()
            }
            
             do {
                try self.initTriggerEngine()
                self.state = .active
            } catch {
                self.state = .inactive
                log.debug("error: \(error)")
                
                // initTriggerEngine() throws only KeywordDetectorError
                // swiftlint:disable force_cast
                self.post(error as! KeywordDetectorError)
                // swiftlint:enable force_cast
            }
        }
    }

    /**
     Put  pcm data to the engine
     - Parameter buffer: PCM buffer contained voice data
     */
    public func putAudioBuffer(buffer: AVAudioPCMBuffer) {
        kwdQueue.async { [weak self] in
            guard let self = self else { return }
            guard let ptrPcmData = buffer.int16ChannelData?.pointee,
                0 < buffer.frameLength else {
                    log.warning("There's no 16bit audio data.")
                    return
            }
            
            ptrPcmData.withMemoryRebound(to: UInt8.self, capacity: Int(buffer.frameLength*2)) { (ptrData: UnsafeMutablePointer<UInt8>) -> Void in
                self.detectingData.append(Data(bytes: ptrData, count: Int(buffer.frameLength)*2))
            }
            
            let isDetected = Wakeup_PutAudio(self.engineHandle, ptrPcmData, Int32(buffer.frameLength)) == 1
            if isDetected {
                log.debug("detected")
                self.notifyDetection()
                self.internalStop()
            }
        }
    }
    
    /**
     Stop keyword Detection.
     */
    public func stop() {
        log.debug("try to stop")
        
        kwdQueue.async { [weak self] in
            self?.internalStop()
        }
    }
    
    private func internalStop() {
        if engineHandle != nil {
            Wakeup_Destroy(engineHandle)
            engineHandle = nil
            log.debug("engine is destroyed")
        }
        
        state = .inactive
    }
}

// MARK: - Legacy Trigger Engine

extension TycheKeywordDetectorEngine {
    
    /**
     Initialize Key Word Detector engine.
     It needs certain files of Voice Recognition. But we wrap this and offer the simple API.
     Then only you have to do is making decision which key word you use.
     */
    private func initTriggerEngine() throws {
        if engineHandle != nil {
            Wakeup_Destroy(engineHandle)
        }
        
        guard let wakeUpHandle = Wakeup_Create(keyword.netFilePath, keyword.searchFilePath, 0) else {
            throw KeywordDetectorError.initEngineFailed
        }
        
        engineHandle = wakeUpHandle
    }
}

// MARK: - ETC
extension TycheKeywordDetectorEngine {
    private func notifyDetection() {
        let startMargin = convertTimeToDataOffset(Wakeup_GetStartMargin(engineHandle))
        let start = convertTimeToDataOffset(Wakeup_GetStartTime(engineHandle))
        let end = convertTimeToDataOffset(Wakeup_GetEndTime(engineHandle))
        let detection = convertTimeToDataOffset(Wakeup_GetDetectionTime(engineHandle))
        let base = start - startMargin
        log.debug("base: \(base), startMargin: \(startMargin), start: \(start), end: \(end), detection: \(detection)")
        
        // -------|--startMargin--|-----------|-------|
        //       base           start        end  detection
        let detectedRange = (detectingData.count - (detection - base))..<detectingData.count
        let detectedData = detectingData.subdata(in: detectedRange)
        
        // reset buffers
        detectingData.removeAll()
        
        #if DEBUG
        let filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("detected.raw")
        do {
            log.debug("detected filenlame: \(filename)")
            try detectedData.write(to: filename)
        } catch {
            log.debug(error)
        }
        #endif
        
        post(
            DetectedInfo(
                data: detectedData,
                start: start - base,
                end: end - base,
                detection: detection - base
            )
        )
    }
    
    private func convertTimeToDataOffset(_ time: Int32) -> Int {
        return (Int(time) * KeywordDetectorConst.sampleRate * 2) / 1000
    }
}

// MARK: - Observer

private extension TycheKeywordDetectorEngine {
    func post<Notification: TypedNotification>(_ notification: Notification) {
        NotificationCenter.default.post(name: Notification.name, object: self, userInfo: notification.dictionary)
    }
}

public extension Notification.Name {
    static let keywordDetectorState = Notification.Name(rawValue: "com.sktelecom.romaine.tyche_keyword_detector_engine.state")
    static let keywordDetectorError = Notification.Name(rawValue: "com.sktelecom.romaine.tyche_keyword_detector_engine.error")
    static let keywordDetectorDetectedInfo = Notification.Name(rawValue: "com.sktelecom.romaine.tyche_keyword_detector_engine.detected_info")
}

public extension TycheKeywordDetectorEngine {
    enum State: EnumTypedNotification {
        public static var name: Notification.Name = .keywordDetectorState
        
        case active
        case inactive
    }
    
    enum KeywordDetectorError: Error, EnumTypedNotification {
        public static var name: Notification.Name = .keywordDetectorError
        
        case initEngineFailed
        case initBufferFailed
        case unsupportedAudioFormat
        case noDataAvailable
        case alreadyActivated
    }
    
    struct DetectedInfo: TypedNotification {
        public let data: Data
        public let start: Int
        public let end: Int
        public let detection: Int
        
        public static var name: Notification.Name = .keywordDetectorDetectedInfo
        public static func make(from: [String: Any]) -> TycheKeywordDetectorEngine.DetectedInfo? {
            guard let data = from["data"] as? Data,
                  let start = from["start"] as? Int,
                  let end = from["end"] as? Int,
                  let detection = from["detection"] as? Int else { return nil }
            
            return DetectedInfo(data: data, start: start, end: end, detection: detection)
        }
    }
}
