//
//  MicInputProvider.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 03/05/2019.
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

public class MicInputProvider: AudioProvidable {
    public var isRunning: Bool {
        return audioEngine.isRunning
    }
    
    public var audioFormat: AVAudioFormat?
    private var streamWriter: AudioStreamWritable?
    private let audioEngine = AVAudioEngine()
    private let audioQueue = DispatchQueue(label: "romain_mic_input_audio_queue")
    
    public init(inputFormat: AVAudioFormat? = nil) {
        guard inputFormat != nil else {
            self.audioFormat = AVAudioFormat(commonFormat: MicInputConst.defaultFormat,
                          sampleRate: MicInputConst.defaultSampleRate,
                          channels: MicInputConst.defaultChannelCount,
                          interleaved: MicInputConst.defaultInterLeavingSetting)
            return
        }
        
        self.audioFormat = inputFormat
    }
    
    public func start(streamWriter: AudioStreamWritable) throws {
        guard audioEngine.isRunning == false else {
            log.warning("audio engine is already running")
            return
        }

        try beginTappingMicrophone(streamWriter: streamWriter)
        
        // when audio session interrupted, audio engine will be stopped automatically. so we have to handle it.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioSessionInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(engineConfigurationChange),
                                               name: .AVAudioEngineConfigurationChange,
                                               object: nil)
    }
    
    public func stop() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVAudioEngineConfigurationChange, object: nil)
        
        self.streamWriter?.finish()
        self.streamWriter = nil
        
        self.audioEngine.inputNode.removeTap(onBus: 1)
        self.audioEngine.stop()
    }
    
    private func beginTappingMicrophone(streamWriter: AudioStreamWritable) throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 1)
        
        guard let recordingFormat = audioFormat else {
            log.error("cannot make audioFormat")
            throw MicInputError.audioFormatError
        }

        guard let formatConverter = AVAudioConverter(from: inputFormat, to: recordingFormat) else {
            log.error("cannot make audio converter")
            throw MicInputError.resamplerError(source: inputFormat, dest: recordingFormat)
        }
        
        self.streamWriter = streamWriter
        
        log.info("convert from: \(inputFormat) to: \(recordingFormat)")
        
        if let error = ObjcExceptionCatcher.objcTry({
            inputNode.removeTap(onBus: 1)
            inputNode.installTap(onBus: 1, bufferSize: AVAudioFrameCount(inputFormat.sampleRate/10), format: inputFormat) { [weak self] (buffer, _) in
                guard let self = self else { return }
                
                self.audioQueue.sync {
                    let convertedFrameCount = AVAudioFrameCount((Double(buffer.frameLength) / inputFormat.sampleRate) * recordingFormat.sampleRate)
                    guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat, frameCapacity: convertedFrameCount) else {
                        log.error("cannot make pcm buffer")
                        return
                    }

                    var error: NSError?
                    formatConverter.convert(to: pcmBuffer, error: &error) { _, outStatus in
                        outStatus.pointee = AVAudioConverterInputStatus.haveData
                        return buffer
                    }
                    
                    guard error == nil else {
                        log.error("audio convert error: \(error!)")
                        return
                    }

                    do {
                        try self.streamWriter?.write(pcmBuffer)
                    } catch {
                        log.error(error)
                        inputNode.removeTap(onBus: 1)
                    }
                }
            }
        }) {
            throw error
        }
                
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            log.error(error.localizedDescription)
        }
    }
    
    @objc func audioSessionInterruption(notification: Notification) {
        log.debug("audioSessionInterruption")
        
        guard let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        if type == .ended {
            guard let optionsValue =
                info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                    return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                try? audioEngine.start()
            }
        }
    }
    
    /// recover when the audio engine is stopped by OS.
    @objc func engineConfigurationChange(notification: Notification) {
        log.debug("engineConfigurationChange - \(notification)")
        
        guard audioEngine.isRunning == false else { return }
        guard let streamWriter = streamWriter else { return }

        try? beginTappingMicrophone(streamWriter: streamWriter)

    }
}
