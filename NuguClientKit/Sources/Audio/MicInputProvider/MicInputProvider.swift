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

import NuguObjcUtils

/// Record audio input from a microphone.
public class MicInputProvider {
    public weak var delegate: MicInputProviderDelegate?
    
    /// Whether the microphone is currently running.
    public var isRunning: Bool {
        return audioEngine.isRunning
    }
    
    /// The format of the PCM audio to be contained in the buffer.
    public var audioFormat: AVAudioFormat?
    private let audioBus = 0
    private let audioEngine = AVAudioEngine()
    private let audioQueue = DispatchQueue(label: "com.sktelecom.romaine.mic_input_audio_queue")
    
    // observers
    private let notificationCenter = NotificationCenter.default
    private var audioEngineConfigurationObserver: Any?
    
    /// Creates an instance of an MicInputProvider.
    /// - Parameter inputFormat: The format of the PCM audio to be contained in the buffer.
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
    
    deinit {
        removeAudioEngineConfigurationObserver()
    }
    
    /// Starts recording from the microphone.
    /// - Parameter tapBlock: a block to be called with audio buffers
    /// - throws: An error of type `MicInputError`
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
    
    /// Starts recording from the microphone.
    ///
    /// Audio buffers are passed through `MicInputProviderDelegate.micInputProviderDidReceive(buffer:)`.
    /// - throws: An error of type `MicInputError`
    public func start() throws {
        try start { [weak self] (buffer, _) in
            self?.delegate?.micInputProviderDidReceive(buffer: buffer)
        }
    }
    
    /// Stops recording from the microphone.
    public func stop() {
        log.debug("Try to stop")
        removeAudioEngineConfigurationObserver()
        
        if let error = UnifiedErrorCatcher.try({
            guard audioEngine.isRunning else {
                log.debug("MicInput is not running")
                return nil
            }
            
            audioEngine.inputNode.removeTap(onBus: audioBus)
            audioEngine.stop()
            log.debug("MicInput is stopped")
            return nil
        }) {
            log.error("stop error: \(error)\n")
        }
    }
    
    private func beginTappingMicrophone(tapBlock: @escaping AVAudioNodeTapBlock) throws {
        log.debug("begin tapping to engine's input node")
        
        var inputNode: AVAudioInputNode!
        var inputFormat: AVAudioFormat!
        if let error = UnifiedErrorCatcher.try({
            // The audio engine creates a singleton on demand when inputNode is first accessed.
            // So it could raise an ObjC exception
            inputNode = audioEngine.inputNode
            inputFormat = inputNode.inputFormat(forBus: audioBus)
            return nil
        }) {
            log.error("create AVAudioInputNode error: \(error.localizedDescription)")
            throw error
        }
        
        guard 0 < inputFormat.channelCount, 0 < inputFormat.sampleRate else {
            log.error("Audio hardware is not available now."
                        + "\ncurrent input node channelCount: \(inputFormat.channelCount), sampleRate: \(inputFormat.sampleRate)"
                        + "\naudio session input data source: \(AVAudioSession.sharedInstance().inputDataSource?.debugDescription ?? "nil")")
            throw MicInputError.audioHardwareError
        }
        
        guard let recordingFormat = audioFormat else {
            log.error("AudioFormat is not available")
            throw MicInputError.audioFormatError
        }
        
        log.info("convert from: \(String(describing: inputFormat)) to: \(recordingFormat)")
        guard let formatConverter = AVAudioConverter(from: inputFormat, to: recordingFormat) else {
            log.error("cannot make audio converter")
            throw MicInputError.resamplerError(source: inputFormat, dest: recordingFormat)
        }
        
        if let error = UnifiedErrorCatcher.try({
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
            
            return nil
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
            addAudioEngineConfigurationObserver()
        } catch {
            log.error(error.localizedDescription)
            throw error
        }
    }
}

extension MicInputProvider {
    func addAudioEngineConfigurationObserver() {
        removeAudioEngineConfigurationObserver()
        
        audioEngineConfigurationObserver = notificationCenter.addObserver(forName: .AVAudioEngineConfigurationChange, object: audioEngine, queue: nil) { [weak self] notification in
            log.debug("notification: \(notification)")
            self?.audioQueue.async { [weak self] in
                self?.stop()
                try? self?.start()
            }
            
            self?.delegate?.audioEngineConfigurationChanged()
        }
    }
    
    func removeAudioEngineConfigurationObserver() {
        if let audioEngineConfigurationObserver = audioEngineConfigurationObserver {
            notificationCenter.removeObserver(audioEngineConfigurationObserver)
            self.audioEngineConfigurationObserver = nil
        }
    }
}
