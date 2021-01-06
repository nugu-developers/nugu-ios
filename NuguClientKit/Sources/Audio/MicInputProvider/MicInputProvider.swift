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

/// <#Description#>
public class MicInputProvider {
    /// <#Description#>
    public var isRunning: Bool {
        return audioEngine.isRunning
    }
    
    /// <#Description#>
    public var audioFormat: AVAudioFormat?
    private let audioBus = 0
    private let audioEngine = AVAudioEngine()
    private let audioQueue = DispatchQueue(label: "romain_mic_input_audio_queue")
    
    /// <#Description#>
    /// - Parameter inputFormat: <#inputFormat description#>
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
    
    /// <#Description#>
    /// - Parameter tapBlock: <#tapBlock description#>
    /// - Throws: <#description#>
    public func start(tapBlock: @escaping AVAudioNodeTapBlock) throws {
        guard audioEngine.isRunning == false else {
            log.warning("audio engine is already running")
            return
        }
        
        do {
            try beginTappingMicrophone(tapBlock: tapBlock)
        } catch {
            stop() // Unless Mic input is opened, It should be reset
            throw error
        }
    }
    
    /// <#Description#>
    public func stop() {
        log.debug("try to stop")
        
        if let error = NCObjcExceptionCatcher.objcTry({
            audioEngine.inputNode.removeTap(onBus: audioBus)
            audioEngine.stop()
        }) {
            log.error("stop error: \(error)\n")
        }
    }
    
    private func beginTappingMicrophone(tapBlock: @escaping AVAudioNodeTapBlock) throws {
        log.debug("begin tapping to engine's input node")
        
        var inputNode: AVAudioInputNode!
        var inputFormat: AVAudioFormat!
        if let error = NCObjcExceptionCatcher.objcTry({
            // The audio engine creates a singleton on demand when inputNode is first accessed.
            // So it could raise an ObjC exception
            inputNode = audioEngine.inputNode
            inputFormat = inputNode.inputFormat(forBus: audioBus)
        }) {
            log.error("create AVAudioInputNode error: \(error.localizedDescription)")
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
        
        if let error = NCObjcExceptionCatcher.objcTry({
            inputNode.removeTap(onBus: audioBus)
            inputNode.installTap(onBus: audioBus, bufferSize: AVAudioFrameCount(inputFormat.sampleRate/10), format: inputFormat) { [weak self] (buffer, when) in
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
                    
                    tapBlock(pcmBuffer, when)
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
