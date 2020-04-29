//
//  SpeechSynthesizer.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 24/01/2019.
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

import RxSwift

/**
 Player for Nugu voice (Text To Speech)
 - Nugu server will send a tts message which is encoded opus codec.
 */
public class OpusPlayer: MediaPlayable {
    private var engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var audioFormat: AVAudioFormat
    private lazy var chunkSize = Int(audioFormat.sampleRate / 5) // 200ms
    
    /// To notify last audio buffer is consumed.
    private var lastBuffer: AVAudioPCMBuffer?
    
    /// Index of buffer to be scheduled
    private var curBufferIndex = 0
    
    /// If samples which is not enough to make chunk appended, It should be stored tempAudioArray and wait for other samples.
    private var tempAudioArray = [Float]()

    /// hold entire audio buffers for seek function.
    @Publish private var audioBuffers = [AVAudioPCMBuffer]()
    private let disposeBag = DisposeBag()
    
    private var audioQueue = DispatchQueue(label: "com.sktelecom.romaine.speech_synthesizer_audio")
    
    #if DEBUG
    private var appendedData = Data()
    private var consumedData = Data()
    #endif

    public var isPaused = false
    public weak var delegate: MediaPlayerDelegate?
    
    /// current time
    public var offset: TimeIntervallic {
        return NuguTimeInterval(seconds: Double(chunkSize * curBufferIndex) / audioFormat.sampleRate)
    }
    
    /// duration
    public var duration: TimeIntervallic {
        return NuguTimeInterval(seconds: Double(chunkSize * audioBuffers.count) / audioFormat.sampleRate)
    }
    
    public var volume: Float {
        get {
            return player.volume
        }
        set {
            player.volume = newValue
        }
    }
    
    public init() {
        // unless channels argument is more than 2, init() won't return nil.
        // we use fixed-audio-format because tts server does.
        self.audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: OpusPlayerConst.audioSampleRate, channels: 1, interleaved: false)!
        engine.attach(player)
        
        // To control volume, player node should be connected to mixer node.
        self.engine.connect(self.player, to: self.engine.mainMixerNode, format: self.audioFormat)
        try? self.engineInit()
        self.engine.prepare()
    }
    
    public var isPlaying: Bool {
        return player.isPlaying
    }
    
    /**
     Play opus data.
     - You can call this method anytime you want. (this player doesn't care whether entire Opus data was appened or not)
     */
    public func play() {
        log.debug("try to play opus data")
        
        do {
            try self.engineInit()
        } catch {
            self.delegate?.mediaPlayerDidChange(state: .error(error: error))
        }
        
        if let objcException = (ObjcExceptionCatcher.objcTry {
            log.debug("try to start player")
            self.player.play()
            self.isPaused = false
            self.delegate?.mediaPlayerDidChange(state: .start)
            log.debug("player started")
        }) {
            self.delegate?.mediaPlayerDidChange(state: .error(error: objcException))
            return
        }
        
        // when audio session interrupted, audio engine will be stopped automatically. so we have to handle it.
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterruption), name: AVAudioSession.interruptionNotification, object: nil)

        // if audio session is changed and influence AVAudioEngine, we should handle this.
        NotificationCenter.default.removeObserver(self, name: .AVAudioEngineConfigurationChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(engineConfigurationChange), name: .AVAudioEngineConfigurationChange, object: nil)
    }
    
    public func pause() {
        log.debug("try to pause")
        player.pause()
        isPaused = true
        delegate?.mediaPlayerDidChange(state: .pause)
    }
    
    public func resume() {
        play()
    }
    
    public func stop() {
        log.debug("try to stop")
        reset()
        delegate?.mediaPlayerDidChange(state: .stop)
    }
    
    /**
     seek
     - parameter to: seek time (millisecond)
     */
    public func seek(to offset: TimeIntervallic, completion: ((Result<Void, Error>) -> Void)?) {
        log.debug("try to seek")

        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard (0..<self.duration.truncatedSeconds).contains(offset.truncatedSeconds) else {
                completion?(.failure(OpusPlayerError.seekRangeExceed))
                return
            }
            
            let chunkTime = Int((Float(self.chunkSize) / Float(self.audioFormat.sampleRate)) * 1000)
            self.curBufferIndex = offset.truncatedSeconds / chunkTime
            completion?(.success(()))
        }
    }
}

// MARK: - OpusPlayer + MediaOpusStreamDataSource

extension OpusPlayer: MediaOpusStreamDataSource {
    /**
     This function should be called If you append last data.
     - Though player has less amount of samples than chunk size, But player will play it when this api is called.
     - Player can calculate duration of TTS.
     */
    public func lastDataAppended() throws {
        log.debug("last data appended. no data can be appended any longer.")

        guard lastBuffer == nil else {
            throw OpusPlayerError.audioBufferClosed
        }
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            if 0 < self.tempAudioArray.count, let lastPcmData = self.tempAudioArray.pcmBuffer(format: self.audioFormat) {
                log.debug("temp audio data will be scheduled. because it is last data.")
                self.audioBuffers.append(lastPcmData)
            }
            
            self.lastBuffer = self.audioBuffers.last
            self.tempAudioArray.removeAll()
            
            // last data received but recursive scheduler is not started yet.
            if self.curBufferIndex == 0 {
                self.curBufferIndex += (self.audioBuffers.count - 1)
                for audioBuffer in self.audioBuffers {
                    self.scheduleBuffer(audioBuffer: audioBuffer)
                }
            }
            
            log.debug("duration: \(self.duration)")
        }
    }
    
    /**
     Player keeps All data for calculating offset and offering seek-function
     The data appended must be separated to suitable chunk size (200ms)
     - parameter data: the data to be decoded and played.
     */
    public func appendData(_ data: Data) throws {
        #if DEBUG
        self.appendedData.append(data)
        #endif
        
        guard lastBuffer == nil else {
            throw OpusPlayerError.audioBufferClosed
        }

        audioQueue.async { [weak self] in
            guard let self = self else { return }

            guard let pcmData = try? OpusDecoder.shared.decode(data: data) else {
                log.error("opus decode failed")
                self.delegate?.mediaPlayerDidChange(state: .error(error: OpusPlayerError.decodeFailed))
                return
            }
            
            // Lasting audio data has to be added to schedule it.
            var audioDataArray = [Float]()
            if 0 < self.tempAudioArray.count {
                audioDataArray.append(contentsOf: self.tempAudioArray)
                log.debug("temp audio processing: \(self.tempAudioArray.count)")
                self.tempAudioArray.removeAll()
            }
            audioDataArray.append(contentsOf: pcmData)
            
            var bufferPosition = 0
            var pcmBufferArray = [AVAudioPCMBuffer]()
            while bufferPosition < audioDataArray.count {
                // if it's not a last data but smaller than chunk size, put it into the tempAudioArray for future processing
                guard bufferPosition + self.chunkSize < audioDataArray.count else {
                    self.tempAudioArray.append(contentsOf: audioDataArray[bufferPosition..<audioDataArray.count])
                    log.info("tempAudio size: \(self.tempAudioArray.count), chunkSize: \(self.chunkSize)")
                    break
                }
                
                // though the data is smaller than chunk, but it has to be scheduled.
                let bufferSize = min(self.chunkSize, audioDataArray.count - bufferPosition)
                let chunk = Array(audioDataArray[bufferPosition..<(bufferPosition + bufferSize)])
                guard let pcmBuffer = chunk.pcmBuffer(format: self.audioFormat) else {
                    continue
                }
                
                pcmBufferArray.append(pcmBuffer)
                bufferPosition += bufferSize
            }
            
            if 0 < pcmBufferArray.count {
                self.audioBuffers.append(contentsOf: pcmBufferArray)
                self.prepareBuffer()
            }
        }
    }
}

// MARK: - OpusPlayer + Private

private extension OpusPlayer {
    func engineInit() throws {
        if let objcException = (ObjcExceptionCatcher.objcTry { [weak self] in
            guard let self = self else {
                return
            }

            if self.engine.isRunning == false {
                try? self.engine.start()
                log.debug("engine started")
            }
        }) {
            self.delegate?.mediaPlayerDidChange(state: .error(error: objcException))
            throw objcException
        }
    }
    
    /**
     SpeechSynthesizer must have jitter buffers to play.
     First of all, schedule jitter size of Buffers at ones.
     When the buffer of index(N)  consumed, buffer of index(N+jitterSize) will be scheduled.
     - seealso: scheduleBuffer()
     */
    func prepareBuffer() {
        if self.curBufferIndex == 0, self.curBufferIndex + OpusPlayerConst.audioJitterSize < self.audioBuffers.count {
            for bufferIndex in self.curBufferIndex..<(self.curBufferIndex + OpusPlayerConst.audioJitterSize) {
                if let audioBuffer = self.audioBuffers[safe: bufferIndex] {
                    self.scheduleBuffer(audioBuffer: audioBuffer)
                }
            }
            
            self.curBufferIndex += (OpusPlayerConst.audioJitterSize - 1)
        }
    }
    
    /// schedule buffer and check last data was consumed on it's closure.
    func scheduleBuffer(audioBuffer: AVAudioPCMBuffer) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.player.scheduleBuffer(audioBuffer) { [weak self] in
                self?.audioQueue.async { [weak self] in
                    guard let self = self else { return }
                    
                    #if DEBUG
                    if let channelData = audioBuffer.floatChannelData?.pointee {
                        let scheduledData = Data(bytes: channelData, count: Int(audioBuffer.frameLength)*4)
                        self.consumedData.append(scheduledData)
                    }
                    #endif
                    
                    guard audioBuffer != self.lastBuffer else {
                        self.reset()
                        self.delegate?.mediaPlayerDidChange(state: .finish)
                        
                        #if DEBUG
                        OpusDecoder.shared.dump()
                        let appendedFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("silver_tray_appended.raw")
                        let consumedFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("silver_tray_consumed.raw")
                        do {
                            if let allPCMArray = try? OpusDecoder.shared.decode(data: self.appendedData) {
                                let allData = Data(bytes: allPCMArray, count: allPCMArray.count*4)
                                try allData.write(to: appendedFilename)
                                try self.consumedData.write(to: consumedFilename)
                                
                                log.debug("appended data to file :\(appendedFilename)")
                                log.debug("consumed data to file :\(consumedFilename)")
                            }
                        } catch {
                            log.debug(error)
                        }
                        #endif
                        
                        return
                    }
                    
                    guard let curBuffer = self.audioBuffers[safe: self.curBufferIndex],
                        curBuffer != self.lastBuffer else {
                            return
                    }
                    
                    self.curBufferIndex += 1
                    guard let nextBuffer = self.audioBuffers[safe: self.curBufferIndex] else {
                        log.debug("waiting for next audio data.")
                        
                        self.$audioBuffers
                            .take(1)
                            .subscribeOn(CurrentThreadScheduler.instance)
                            .subscribe(onNext: { [weak self] (audioBuffers) in
                                guard let self = self,
                                    let nextBuffer = audioBuffers[safe: self.curBufferIndex] else { return }
                                
                                log.debug("Try to restart scheduler.")
                                self.scheduleBuffer(audioBuffer: nextBuffer)
                        }).disposed(by: self.disposeBag)
                        return
                    }
                    
                    self.scheduleBuffer(audioBuffer: nextBuffer)
                }
            }
        }
    }
    
    /**
     Notification must removed before engine stopped.
     Or you may face to exception from inside of AVAudioEngine.
     - ex) AVAudioSession is changed when the audio engine is stopped. but this notification is not removed yet.
     */
    func reset() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVAudioEngineConfigurationChange, object: nil)
        
        self.player.stop()
        self.engine.stop()
        self.isPaused = false
        self.lastBuffer = nil
        self.curBufferIndex = 0
        self.tempAudioArray.removeAll()
        self.audioBuffers.removeAll()
    }
}

// MARK: - OpusPlayer + Notification

@objc private extension OpusPlayer {
    func audioSessionInterruption(notification: Notification) {
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
                if let objcException = (ObjcExceptionCatcher.objcTry { [weak self] in
                    guard let self = self else { return }
                    log.debug("resume offset: \(self.offset.truncatedSeconds)")
                    if self.player.isPlaying == false {
                        self.engine.connect(self.player, to: self.engine.mainMixerNode, format: self.audioFormat)
                    }
                    
                    try? self.engineInit()
                }) {
                    delegate?.mediaPlayerDidChange(state: .error(error: objcException))
                }
            }
        }
    }

    func engineConfigurationChange(notification: Notification) {
        log.debug("engineConfigurationChange: \(notification)")

        if let objcException = (ObjcExceptionCatcher.objcTry { [weak self] in
            guard let self = self else { return }
            if self.player.isPlaying {
                log.debug("resume offset: \(self.offset.truncatedSeconds)")
                if self.player.isPlaying == false {
                    self.engine.connect(self.player, to: self.engine.mainMixerNode, format: self.audioFormat)
                }
                
                try? self.engineInit()
            }
        }) {
            delegate?.mediaPlayerDidChange(state: .error(error: objcException))
        }
    }
}

// MARK: - Array + AVAudioPCMBuffer

private extension Array where Element == Float {
    func pcmBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(count)) else { return nil }
        pcmBuffer.frameLength = pcmBuffer.frameCapacity
        
        if let monoBuffer = pcmBuffer.floatChannelData?[0] {
            monoBuffer.assign(from: self, count: count)
        }
        
        return pcmBuffer
    }
}
