//
//  DataStreamPlayer.swift
//  SilverTray
//
//  Created by childc on 24/01/2019.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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
import os.log

import NuguUtils
import NuguObjcUtils

/**
 Player for data chunks
 */
public class DataStreamPlayer {
    private static let audioEngineManager = AudioEngineManager<DataStreamPlayer>()
    @Atomic private static var id: UInt = 0
    
    internal let id: UInt
    private let player = AVAudioPlayerNode()
    
    #if !os(watchOS)
    private let speedController = AVAudioUnitVarispeed()
    private let pitchController = AVAudioUnitTimePitch()
    #endif
    
    private let audioFormat: AVAudioFormat
    private let jitterBufferSize = 2 // Use 2 chunks as a jitter buffer
    private let bufferTimeout: DispatchTimeInterval = .seconds(30) // Wait for next buffer until this time.
    private lazy var chunkSize = Int(audioFormat.sampleRate / 10) // 100ms
    
    /// To notify last audio buffer is consumed.
    private var lastBuffer: AVAudioPCMBuffer?
    
    /// Index of buffer to be scheduled
    private var scheduleBufferIndex = 0
    
    /// Index of consumed buffer
    private var consumedBufferIndex: Int?
    
    /// If samples which is not enough to make chunk appended, It should be stored tempAudioArray and wait for other samples.
    private var tempAudioArray = [Float]()

    /// hold entire audio buffers for seek function.
    private var audioBuffers = [AVAudioPCMBuffer]() {
        didSet {
            if oldValue.count < audioBuffers.count {
                notificationCenter.post(name: .audioBufferChange, object: self, userInfo: nil)
            }
        }
    }
    
    private let audioQueue = DispatchQueue(label: "com.sktelecom.romain.silver_tray.player_queue")
    private let notificationCenter = NotificationCenter.default
    private var audioBufferObserver: Any?
    private var audioBufferCancelItem: DispatchWorkItem?
    
    #if DEBUG
    private var appendedData = Data()
    private var consumedData = Data()
    #endif

    public let decoder: AudioDecodable
    public weak var delegate: DataStreamPlayerDelegate?
    
    /// current player state
    public var state: DataStreamPlayerState = .idle {
        didSet {
            if oldValue != state {
                os_log("[%@] state changed: %@", log: .player, type: .debug, "\(id)", "\(state)")
                delegate?.dataStreamPlayerStateDidChange(state)
            }
        }
    }
    
    /// current buffer state
    @Atomic public var bufferState: DataStreamPlayerBufferState = .bufferEmpty {
        didSet {
            if bufferState != oldValue {
                os_log("[%@] buffer state changed: %@", log: .player, type: .debug, "\(id)", "\(bufferState)")
                delegate?.dataStreamPlayerBufferStateDidChange(bufferState)
                
                if bufferState == .likelyToKeepUp {
                    audioBufferCancelItem?.cancel()
                    return
                }

                audioBufferCancelItem?.cancel()
                let audioBufferCancelItem = DispatchWorkItem { [weak self] in
                    self?.stop()
                }
                audioQueue.asyncAfter(deadline: .now() + bufferTimeout, execute: audioBufferCancelItem)
                self.audioBufferCancelItem = audioBufferCancelItem
            }
        }
    }
    
    /// current time
    public var offset: Int {
        return Int((Double(chunkSize * scheduleBufferIndex) / audioFormat.sampleRate) * 1000)
    }
    
    /// duration
    public var duration: Int {
        return Int((Double(chunkSize * audioBuffers.count) / audioFormat.sampleRate) * 1000)
    }
    
    public var volume: Float {
        get {
            return player.volume
        }
        set {
            player.volume = newValue
        }
    }
    
    #if !os(watchOS)
    public var speed: Float {
        get {
            return speedController.rate
        }
        
        set {
            speedController.rate = newValue
        }
    }
    
    public var pitch: Float {
        get {
            return pitchController.pitch
        }
        
        set {
            pitchController.pitch = newValue
        }
    }
    #endif
    
    /**
     Initialize `DataStreamPlayer`.

     - If you use the same format of decoder, You can use `init(decoder: AudioDecodable)`
     */
    public init(decoder: AudioDecodable, audioFormat: AVAudioFormat) throws {
        // Identification
        var id: UInt = 0
        DataStreamPlayer._id.mutate {
            if $0 == UInt.max {
                $0 = 0
            }
            id = $0
            $0 += 1
        }
        
        self.id = id
        self.audioFormat = audioFormat
        self.decoder = decoder
        
        if let error = UnifiedErrorCatcher.try ({
            // Attach nodes to the engine
            attachAudioNodes()
            
            // Connect AudioPlayer to the engine
            connectAudioChain()
            
            return nil
        }) {
            throw error
        }
        
        // Hold this instance because properties of this should not be released outside.
        Self.audioEngineManager.registerObserver(self)
    }
    
    /**
     Initialize without `AVAudioFormat`
     
     AVAudioFormat follows decoder's format will be created automatically.
     */
    public convenience init(decoder: AudioDecodable) throws {
        guard let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                              sampleRate: decoder.sampleRate,
                                              channels: AVAudioChannelCount(decoder.channels),
                                              interleaved: false) else {
                                                throw DataStreamPlayerError.unsupportedAudioFormat
        }
        
        try self.init(decoder: decoder, audioFormat: audioFormat)
    }
    
    private func attachAudioNodes() {
        #if !os(watchOS)
        Self.audioEngineManager.attach(speedController)
        Self.audioEngineManager.attach(pitchController)
        #endif
        
        Self.audioEngineManager.attach(player)
    }
    
    private func detachAudioNodes() {
        #if !os(watchOS)
        Self.audioEngineManager.detach(speedController)
        Self.audioEngineManager.detach(pitchController)
        #endif
        
        Self.audioEngineManager.detach(player)
    }

    
    private func connectAudioChain() {
        if let error = (UnifiedErrorCatcher.try { () -> Error? in
            #if os(watchOS)
            Self.audioEngineManager.connect(player, to: Self.audioEngineManager.mainMixerNode, format: audioFormat)
            #else
            // To control speed, Put speedController into the chain
            // Pitch controller has rate too. But if you adjust it without pitch value, you will get unexpected audio rate.
            Self.audioEngineManager.connect(player, to: speedController, format: audioFormat)
            
            // To control pitch, Put pitchController into the chain
            Self.audioEngineManager.connect(speedController, to: pitchController, format: audioFormat)
            
            // To control volume, Last of chain must me mixer node.
            Self.audioEngineManager.connect(pitchController, to: Self.audioEngineManager.mainMixerNode, format: audioFormat)
            #endif
            
            return nil
        }) {
            os_log("[%@] connection failed: %@", log: .player, type: .error, "\(id)", "\(error)")
        }
    }
    
    private func disconnectAudioChain() {
        if let error = UnifiedErrorCatcher.try({ () -> Error? in
            #if !os(watchOS)
            Self.audioEngineManager.disconnectNodeOutput(pitchController)
            Self.audioEngineManager.disconnectNodeOutput(speedController)
            #endif
            
            Self.audioEngineManager.disconnectNodeOutput(player)
            
            return nil
        }) {
            os_log("[%@] disconnection failed: %@", log: .player, type: .error, "\(id)", "\(error)")
        }
    }
    
    public var isPlaying: Bool {
        return player.isPlaying
    }
    
    /**
     Play audio data.
     - You can call this method anytime you want. (this player doesn't care whether entire audio data was appened or not)
     */
    public func play() {
        os_log("[%@] try to play data stream", log: .player, type: .debug, "\(id)")

        audioQueue.async { [weak self] in
            self?.internalPlay()
        }
    }
    
    private func internalPlay() {
        do {
            try Self.audioEngineManager.startAudioEngine()
        } catch {
             os_log("[%@] audioEngine start failed", log: .audioEngine, type: .debug, "\(id)")
        }
        
        if let error = (UnifiedErrorCatcher.try {
            player.play()
            os_log("[%@] player started", log: .player, type: .debug, "\(id)")
            
            state = .start
            return nil
        }) {
            os_log("[%@] player start failed: %@", log: .player, type: .error, "\(id)", "\(error)")
            printAudioLogs()
            reset()
            state = .error(error)
            return
        }
    }
    
    public func pause() {
        os_log("[%@] try to pause", log: .player, type: .debug, "\(id)")
        audioQueue.async { [weak self] in
            self?.player.pause()
            self?.state = .pause
        }
    }
    
    public func resume() {
        play()
    }
    
    public func stop() {
        os_log("[%@] try to stop", log: .player, type: .debug, "\(id)")
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.reset()
            self.state = .stop
        }
    }
    
    /**
     Stop AVAudioPlayerNode.
     */
    func reset() {
        audioBufferCancelItem?.cancel()
        
        if let audioBufferObserver = audioBufferObserver {
            notificationCenter.removeObserver(audioBufferObserver)
        }
        
        // Detach nodes
        if let error = (UnifiedErrorCatcher.try {
            disconnectAudioChain()
            detachAudioNodes()
            return nil
        }) {
            os_log("[%@] detaching nodes failed: %@", log: .player, type: .error, "\(id)", "\(error)")
        }
        
        // Stop player node
        if let error = (UnifiedErrorCatcher.try {
            player.stop()
            return nil
        }) {
            os_log("[%@] stopping player node failed: %@", log: .player, type: .error, "\(id)", "\(error)")
        }
        
        lastBuffer = nil
        scheduleBufferIndex = 0
        tempAudioArray.removeAll()
        audioBuffers.removeAll()
        
        if Self.audioEngineManager.removeObserver(self) == nil {
            os_log("[%@] removing observer failed", log: .player, type: .default, "\(id)")
        }
        
        #if DEBUG
        let appendedFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("silver_tray_appended.encoded")
        let consumedFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("silver_tray_consumed.raw")
        do {
            // write consumedData to file
            try self.appendedData.write(to: appendedFilename)
            try self.consumedData.write(to: consumedFilename)
            
            os_log("[%@] appended data to file: %{private}@", log: .player, type: .debug, "\(id)", "\(appendedFilename)")
            os_log("[%@] consumed data to file: %{private}@", log: .player, type: .debug, "\(id)", "\(consumedFilename)")
        } catch {
            os_log("[%@] file write failed: %@", log: .player, type: .error, "\(id)", "\(error)")
        }
        
        appendedData.removeAll()
        consumedData.removeAll()
        #endif
    }
    
    /**
     seek
     - parameter to: seek time (millisecond)
     */
    public func seek(to offset: Int, completion: ((Result<Void, Error>) -> Void)?) {
        os_log("[%@] try to seek: %@", log: .player, type: .debug, "\(id)", "\(offset)")

        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard (0..<self.duration).contains(offset) else {
                completion?(.failure(DataStreamPlayerError.seekRangeExceed))
                return
            }
            
            let chunkTime = Int((Float(self.chunkSize) / Float(self.audioFormat.sampleRate)) * 1000)
            self.scheduleBufferIndex = offset / chunkTime
            os_log("[%@] seek to index: %@", log: .player, type: .debug, "\(self.id)", "\(self.scheduleBufferIndex)")
            completion?(.success(()))
        }
    }
}

// MARK: append data

extension DataStreamPlayer {
    /**
     This function should be called If you append last data.
     - Though player has less amount of samples than chunk size, But player will play it when this api is called.
     - Player can calculate duration of TTS.
     */
    public func lastDataAppended() throws {
        os_log("[%@] last data appended. No data can be appended any longer.", log: .player, type: .debug, "\(id)")
        
        try audioQueue.sync {
            guard lastBuffer == nil else {
                throw DataStreamPlayerError.audioBufferClosed
            }
        }
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            if 0 < self.tempAudioArray.count, let lastPcmData = self.tempAudioArray.pcmBuffer(format: self.audioFormat) {
                os_log("[%@] temp audio data will be scheduled. Because it is last data.", log: .player, type: .debug, "\(self.id)")
                self.audioBuffers.append(lastPcmData)
            }
            
            self.lastBuffer = self.audioBuffers.last
            self.tempAudioArray.removeAll()
            
            guard 0 < self.audioBuffers.count else {
                os_log("[%@] no data appended.", log: .player, type: .info, "\(self.id)")
                self.finish()
                return
            }
            
            // last data received but recursive scheduler is not started yet.
            if self.scheduleBufferIndex == 0 {
                self.scheduleBufferIndex += (self.audioBuffers.count - 1)
                for audioBuffer in self.audioBuffers {
                    self.scheduleBuffer(audioBuffer: audioBuffer)
                }
            }
            
            os_log("[%@] duration: %@", log: .player, type: .debug, "\(self.id)", "\(self.duration)")
            self.delegate?.dataStreamPlayerDidComputeDuration(self.duration)
        }
    }
    
    /**
     Player keeps All data for calculating offset and offering seek-function
     The data appended must be separated to suitable chunk size (200ms)
     - parameter data: the data to be decoded and played.
     */
    public func appendData(_ data: Data) throws {
        try audioQueue.sync {
            guard lastBuffer == nil else {
                throw DataStreamPlayerError.audioBufferClosed
            }
        }
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            #if DEBUG
            self.appendedData.append(data)
            #endif
            
            let pcmData: [Float]
            do {
                pcmData = try self.decoder.decode(data: data)
            } catch {
                os_log("[%@] decode failed", log: .decoder, type: .error, "\(self.id)")
                self.reset()
                self.state = .error(error)
                return
            }

            // Lasting audio data has to be added to schedule it.
            var audioDataArray = [Float]()
            if 0 < self.tempAudioArray.count {
                audioDataArray.append(contentsOf: self.tempAudioArray)
//                log.debug("temp audio processing: \(self.tempAudioArray.count)")
                self.tempAudioArray.removeAll()
            }
            audioDataArray.append(contentsOf: pcmData)
            
            var bufferPosition = 0
            var pcmBufferArray = [AVAudioPCMBuffer]()
            while bufferPosition < audioDataArray.count {
                // If it's not a last data but smaller than chunk size, Put it into the tempAudioArray for future processing
                guard bufferPosition + self.chunkSize < audioDataArray.count else {
                    self.tempAudioArray.append(contentsOf: audioDataArray[bufferPosition..<audioDataArray.count])
//                    log.debug("tempAudio size: \(self.tempAudioArray.count), chunkSize: \(self.chunkSize)")
                    break
                }
                
                // Though the data is smaller than chunk, But it has to be scheduled.
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

    /**
     To get data from file or remote repository.
     - You are not supposed to use this method on MainThread for getting data using network
     */
    func setSource(url: String) throws {
        guard lastBuffer != nil else { throw DataStreamPlayerError.audioBufferClosed }
        guard let resourceURL = URL(string: url) else { throw DataStreamPlayerError.unavailableSource }
        
        let resourceData = try Data(contentsOf: resourceURL)
        try appendData(resourceData)
    }
}

// MARK: private functions
private extension DataStreamPlayer {
    /**
     DataStreamPlayer has jitter buffers to play stably.
     First of all, schedule jitter size of Buffers at ones.
     When the buffer of index(N)  consumed, buffer of index(N+jitterSize) will be scheduled.
     - seealso: scheduleBuffer()
     */
    func prepareBuffer() {
        guard scheduleBufferIndex == 0, jitterBufferSize < audioBuffers.count else { return }
        
        // schedule audio buffers to play
        for bufferIndex in 0..<jitterBufferSize {
            if let audioBuffer = audioBuffers[safe: bufferIndex] {
                scheduleBufferIndex = bufferIndex
                scheduleBuffer(audioBuffer: audioBuffer)
            }
        }
        
        bufferState = .likelyToKeepUp
    }
    
    /// schedule buffer and check last data was consumed on it's closure.
    func scheduleBuffer(audioBuffer: AVAudioPCMBuffer) {
        let bufferHandler: AVAudioNodeCompletionHandler = { [weak self] in
            self?.audioQueue.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.dataStreamPlayerDidPlay(audioBuffer)
                
                // Though engine is not running, But this clousure can be called,
                // Scheduled buffer might not be played. but just be flushed in this situation.
                if Self.audioEngineManager.isRunning == true {
                    self.consumedBufferIndex = self.audioBuffers.firstIndex(of: audioBuffer)
                } else {
                    os_log("[%@] flushed audioBuffer index: %@", log: .player, type: .info, "\(self.id)", "\(self.audioBuffers.firstIndex(of: audioBuffer) ?? -1)")
                }
                
                #if DEBUG
                if let channelData = audioBuffer.floatChannelData?.pointee {
                    let consumedData = Data(bytes: channelData, count: Int(audioBuffer.frameLength)*4)
                    self.consumedData.append(consumedData)
                }
                #endif
                
                // Though player was already stopped. But closure is called
                // This situation will be occured often. Because retrieving audio data from DSP is very hard
                guard [.finish, .stop].contains(self.state) == false else { return }
                
                // If player consumed last buffer
                guard audioBuffer != self.lastBuffer else {
                    self.finish()
                    return
                }
                
                guard let nextBuffer = self.audioBuffers[safe: self.scheduleBufferIndex] else {
                    guard self.lastBuffer == nil else { return }
                    os_log("[%@] waiting for next audio data.", log: .player, type: .debug, "\(self.id)")
                    self.bufferState = .bufferEmpty
                    
                    self.audioBufferObserver = self.notificationCenter.addObserver(forName: .audioBufferChange, object: self, queue: nil) { [weak self] (notification) in
                        self?.audioQueue.async { [weak self] in
                            guard let self = self else { return }
                            guard self.bufferState == .bufferEmpty else { return }
                            guard let nextBuffer = self.audioBuffers[safe: self.scheduleBufferIndex] else { return }
                            
                            os_log("[%@] Try to restart scheduler.", log: .player, type: .debug, "\(self.id)")
                            self.bufferState = .likelyToKeepUp
                            self.scheduleBuffer(audioBuffer: nextBuffer)
                            
                            if let audioBufferObserver = self.audioBufferObserver {
                                self.notificationCenter.removeObserver(audioBufferObserver)
                            }
                        }
                    }
                    
                    return
                }
                
                self.scheduleBuffer(audioBuffer: nextBuffer)
            }
        }

        if let error = UnifiedErrorCatcher.try({ () -> Error? in
            player.scheduleBuffer(audioBuffer, completionHandler: bufferHandler)
            scheduleBufferIndex += 1
            return nil
        }) {
            os_log("[%@] data schedule error: %@", log: .player, type: .error, "\(id)", "\(error)")
            printAudioLogs(requestBuffer: audioBuffer)
        }
    }
    
    func finish() {
        reset()
        state = .finish
    }
    
    func printAudioLogs(requestBuffer: AVAudioPCMBuffer? = nil) {
        os_log("[%@] audio state:\n\t\trequested format: %@\n\t\tplayer format: %@\n\t\tengine format: %@",
               log: .player, type: .info,
               "\(id)", String(describing: requestBuffer?.format), "\(player.outputFormat(forBus: 0))", "\(Self.audioEngineManager.inputNode.outputFormat(forBus: 0))")
        
        #if !os(macOS)
        os_log("[%@] session state: \n\t\t%@\n\t\t%@\n\t\taudio session sampleRate: %@",
               log: .player, type: .info,
               "\(id)", "\(AVAudioSession.sharedInstance().category)", "\(AVAudioSession.sharedInstance().categoryOptions)", "\(AVAudioSession.sharedInstance().sampleRate)")
        #endif
    }
}

// MARK: - Hashable
extension DataStreamPlayer: Hashable {
    public static func == (lhs: DataStreamPlayer, rhs: DataStreamPlayer) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }
}


// MARK: - AudioEngineObserver

extension DataStreamPlayer: AudioEngineObservable {
    func engineConfigurationChange(notification: Notification) {
        os_log("[%@] player will be paused by changed engine configuration", log: .player, type: .debug, "\(id)")
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            // Notification could be fired though the observer was removed.
            guard [.stop, .finish, .pause].contains(self.state) == false else {
                return
            }

            self.player.pause()
//            let resumeIndex = (self.consumedBufferIndex ?? -1) + 1
//            os_log("[%@] resume index: %@", log: .player, type: .debug, "\(self.id)", "\(resumeIndex)")
//
//            let resumeTime = Int((Float(self.chunkSize) / Float(self.audioFormat.sampleRate)) * 1000) * resumeIndex
//            self.seek(to: resumeTime, completion: { [weak self] _ in
            self.internalPlay()
//            })
        }
    }
}

// MARK: - Array + AVAudioPCMBuffer

private extension Array where Element == Float {
    func pcmBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(count)) else { return nil }
        pcmBuffer.frameLength = pcmBuffer.frameCapacity
        
        if let ptrChannelData = pcmBuffer.floatChannelData?.pointee {
            ptrChannelData.assign(from: self, count: count)
        }
        
        return pcmBuffer
    }
}

// MARK: - Notification

private extension Notification.Name {
    static let audioBufferChange = Notification.Name(rawValue: "com.sktelecom.silver_tray.audio_buffer")
}
