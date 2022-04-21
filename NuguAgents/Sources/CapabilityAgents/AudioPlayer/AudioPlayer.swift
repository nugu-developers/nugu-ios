//
//  AudioPlayer.swift
//  NuguAgents
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/10/20.
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

import NuguCore
import NuguUtils

import RxSwift

protocol AudioPlayerProgressDelegate: AnyObject {
    func audioPlayerDidReportDelay(_ player: AudioPlayer)
    func audioPlayerDidReportInterval(_ player: AudioPlayer)
}

final class AudioPlayer {
    enum PauseReason {
        case nothing
        case focus
        case user
    }
    enum StopReason: String {
        case stop = "STOP"
        case playAnother = "PLAY_ANOTHER"
    }
    
    private(set) var internalPlayer: MediaPlayable?
    weak var delegate: MediaPlayerDelegate?
    weak var progressDelegate: AudioPlayerProgressDelegate?
    
    let payload: AudioPlayerPlayPayload
    let header: Downstream.Header
    var cancelAssociation: Bool = false
    var pauseReason: PauseReason = .nothing
    // https://tde.sktelecom.com/wiki/display/ERECTUS/0.+AudioPlayer+Interface+1.5#id-0.AudioPlayerInterface1.5-8)PlaybackResumed
    // Resume event should be sent as playback started when audio player has been resumed by play directive
    var sendingResumeEventAsPlaybackStarted: Bool = true
    private(set) var stopReason: StopReason = .stop
    
    /// Keep the offset before playback stopped.
    private var lastOffset: TimeIntervallic?
    /// Keep the duration before playback stopped.
    private var lastDuration: TimeIntervallic?
    
    // ProgressReporter
    private var intervalReporter: Disposable?
    private var lastReportedOffset: Int = 0
    
    private var lastDataAppended = false
    
    init(directive: Downstream.Directive) throws {
        payload = try JSONDecoder().decode(AudioPlayerPlayPayload.self, from: directive.payload)
        
        header = directive.header
        
        switch payload.sourceType {
        case .url:
            guard let url = payload.audioItem.stream.url else {
                throw AudioPlayerAgentError.notSupportedSourceType
            }
            let mediaPlayer = MediaPlayer()
            mediaPlayer.setSource(
                url: url,
                offset: NuguTimeInterval(seconds: payload.audioItem.stream.offset),
                cacheKey: payload.cacheKey
            )
            internalPlayer = mediaPlayer
        case .attachment:
            internalPlayer = try OpusPlayer()
        case .none:
            throw AudioPlayerAgentError.notSupportedSourceType
        }
        internalPlayer?.delegate = self
    }
    
    func handleAttachment(_ attachment: Downstream.Attachment) -> Bool {
        guard let dataSource = internalPlayer as? MediaOpusStreamDataSource,
              header.dialogRequestId == attachment.header.dialogRequestId else {
            return false
        }
        guard lastDataAppended == false else {
            return true
        }
        
        do {
            try dataSource.appendData(attachment.content)
            
            if attachment.isEnd {
                lastDataAppended = true
                try dataSource.lastDataAppended()
            }
        } catch {
            log.error(error)
            internalPlayer?.stop()
        }
        return true
    }
    
    // Keep the offset and duration to be sent with playback events.
    private func saveCurrentPlayerState() {
        guard let player = internalPlayer else { return }
        
        lastOffset = player.offset
        lastDuration = player.duration
    }
    
    func pause(reason: PauseReason) {
        pauseReason = reason
        pause()
    }
    
    func stop(reason: StopReason) -> Bool {
        guard let player = internalPlayer else { return false }
        
        stopReason = reason
        if reason == .playAnother {
            cancelAssociation = false
            internalPlayer = nil
            player.delegate = nil
            delegate?.mediaPlayerStateDidChange(.stop, mediaPlayer: self)
        }
        player.stop()
        
        return true
    }
    
    func shouldResume(player: AudioPlayer) -> Bool {
        guard payload.audioItem.stream.token == player.payload.audioItem.stream.token,
                payload.playServiceId == player.payload.playServiceId,
                player.internalPlayer != nil else {
            return false
        }
        return true
    }

    func replacePlayer(_ player: AudioPlayer) {
        guard let internalPlayer = player.internalPlayer else { return }
        
        self.internalPlayer = internalPlayer
        player.internalPlayer = nil
        
        lastReportedOffset = player.lastReportedOffset
        player.stopProgressReport()
        lastDataAppended = player.lastDataAppended
        
        seek(to: NuguTimeInterval(seconds: payload.audioItem.stream.offset))
        
        self.internalPlayer?.delegate = self
    }
}

// MARK: - MediaPlayable

extension AudioPlayer: MediaPlayable {
    var offset: TimeIntervallic {
        return internalPlayer?.offset ?? lastOffset ?? NuguTimeInterval(seconds: 0)
    }
    
    var duration: TimeIntervallic {
        return internalPlayer?.duration ?? lastDuration ?? NuguTimeInterval(seconds: 0)
    }
    
    var volume: Float {
        get { internalPlayer?.volume ?? 1.0 }
        set { internalPlayer?.volume = newValue }
    }
    
    var speed: Float {
        get { internalPlayer?.speed ?? 1.0 }
        set { internalPlayer?.speed = newValue }
    }
    
    func play() {
        internalPlayer?.play()
    }
    
    func stop() {
        saveCurrentPlayerState()
        internalPlayer?.stop()
    }
    
    func pause() {
        internalPlayer?.pause()
    }
    
    func resume() {
        internalPlayer?.resume()
    }
    
    func seek(to offset: TimeIntervallic, completion: ((EndedUp<Error>) -> Void)?) {
        internalPlayer?.seek(to: offset, completion: completion)
    }
}

// MARK: - MediaPlayerDelegate

extension AudioPlayer: MediaPlayerDelegate {
    public func mediaPlayerStateDidChange(_ state: MediaPlayerState, mediaPlayer: MediaPlayable) {
        log.info("media state: \(state)")
        
        switch state {
        case .start, .resume, .likelyToKeepUp:
            startProgressReport()
        default:
            stopProgressReport()
        }
        
        switch state {
        case .finish:
            saveCurrentPlayerState()
            internalPlayer = nil
        case .stop, .error:
            internalPlayer = nil
        default:
            break
        }
        
        delegate?.mediaPlayerStateDidChange(state, mediaPlayer: self)
    }
    
    func mediaPlayerDurationDidChange(_ duration: TimeIntervallic, mediaPlayer: MediaPlayable) {
        delegate?.mediaPlayerDurationDidChange(duration, mediaPlayer: self)
    }
}

// MARK: - Private (Timer)

private extension AudioPlayer {
    func startProgressReport() {
        stopProgressReport()
        let delayReportTime = payload.audioItem.stream.delayReportTime ?? -1
        let intervalReportTime = payload.audioItem.stream.intervalReportTime ?? -1
        guard delayReportTime > 0 || intervalReportTime > 0 else { return }
        
        log.debug("delayReportTime: \(delayReportTime) intervalReportTime: \(intervalReportTime)")
        intervalReporter = Observable<Int>
            .interval(.milliseconds(100), scheduler: SerialDispatchQueueScheduler(qos: .default))
            .map({ [weak self] (_) -> Int in
                guard let seconds = self?.internalPlayer?.offset.seconds,
                      seconds.isNaN == false,
                      seconds.isInfinite == false else {
                    return 0
                }
                return Int(ceil(seconds))
            })
            .filter { [weak self] offset in
                guard let self = self else { return false }
                guard offset > 0 else { return false }
                // Current offset can be smaller than the last offset after seeking.
                guard offset > self.lastReportedOffset else {
                    self.lastReportedOffset = offset
                    return false
                }

                return true
            }
            .subscribe(onNext: { [weak self] (offset) in
                guard let self = self else { return }
                
                // Check if there is any report target between last offset and current offset.
                let offsetRange = (self.lastReportedOffset + 1...offset)
                if delayReportTime > 0, offsetRange.contains(delayReportTime) {
                    self.progressDelegate?.audioPlayerDidReportDelay(self)
                }
                if intervalReportTime > 0, offsetRange.contains(intervalReportTime * (self.lastReportedOffset / intervalReportTime + 1)) {
                    self.progressDelegate?.audioPlayerDidReportInterval(self)
                }
                self.lastReportedOffset = offset
            })
    }
    
    func stopProgressReport() {
        intervalReporter?.dispose()
    }
}
