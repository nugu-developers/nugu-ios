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

import NuguCore.ObjcExceptionCatcher

public class MicInputProvider: AudioProvidable {
    public var isRunning: Bool {
        return audioEngine.isRunning
    }
    
    public var audioFormat: AVAudioFormat?
    private let audioBus = 0
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
        
        do {
            try beginTappingMicrophone(streamWriter: streamWriter)
        } catch {
            stop() // Unless Mic input is opened, It should be reset
            throw error
        }
    }
    
    public func stop() {
        log.debug("try to stop")
        
        streamWriter?.finish()
        streamWriter = nil
        
        audioEngine.inputNode.removeTap(onBus: audioBus)
        audioEngine.stop()
    }
    
    private func beginTappingMicrophone(streamWriter: AudioStreamWritable) throws {
        log.debug("begin tapping to engine's input node")
        self.streamWriter = streamWriter
        
        var inputNode: AVAudioInputNode!
        var inputFormat: AVAudioFormat!
        if let error = ObjcExceptionCatcher.objcTry({
            // The audio engine creates a singleton on demand when inputNode is first accessed.
            // So it could raise an ObjC exception
            inputNode = audioEngine.inputNode
            inputFormat = inputNode.inputFormat(forBus: audioBus)
        }) {
            log.error("create AVAudioInputNode error: \(error)\n" +
                "\t\tengine output format: \(audioEngine.inputNode.outputFormat(forBus: audioBus))\n" +
                "\t\tengine input format: \(audioEngine.inputNode.inputFormat(forBus: audioBus))")
            
            throw error
        }
        
        guard 0 < inputFormat.channelCount,
            let recordingFormat = audioFormat else {
                log.error("AudioFormat is not available")
                throw MicInputError.audioFormatError
        }
        
        log.info("convert from: \(String(describing: inputFormat)) to: \(recordingFormat)")
        guard let formatConverter = AVAudioConverter(from: inputFormat, to: recordingFormat) else {
            log.error("cannot make audio converter")
            throw MicInputError.resamplerError(source: inputFormat, dest: recordingFormat)
        }
        
        if let error = ObjcExceptionCatcher.objcTry({
            inputNode.removeTap(onBus: audioBus)
            inputNode.installTap(onBus: audioBus, bufferSize: AVAudioFrameCount(inputFormat.sampleRate/10), format: inputFormat) { [weak self] (buffer, _) in
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
                        inputNode.removeTap(onBus: self.audioBus)
                    }
                }
            }
        }) {
            log.error("installTap error: \(error)\n" +
                "\t\trequested format: \(String(describing: inputFormat))\n" +
                "\t\tengine output format: \(audioEngine.inputNode.outputFormat(forBus: audioBus))\n" +
                "\t\tengine input format: \(audioEngine.inputNode.inputFormat(forBus: audioBus))")
            log.error("\n\t\t\(AVAudioSession.sharedInstance().category)\n" +
                "\t\t\(AVAudioSession.sharedInstance().categoryOptions)\n" +
                "\t\taudio session sampleRate: \(AVAudioSession.sharedInstance().sampleRate)")
            
            throw error
        }
        
        // installTap() must be called before prepare() or start() on iOS 11.
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            log.error(error.localizedDescription)
            throw error
        }
    }
}
