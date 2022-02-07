//
//  TTSPlayer.swift
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

final class TTSPlayer {
    enum StopReason: String {
        case stop = "STOP"
        case playAnother = "PLAY_ANOTHER"
    }
    
    private(set) var internalPlayer: MediaPlayable?
    weak var delegate: MediaPlayerDelegate?
    
    let payload: TTSSpeakPayload
    let header: Downstream.Header
    var cancelAssociation: Bool = false
    
    init(directive: Downstream.Directive) throws {
        payload = try JSONDecoder().decode(TTSSpeakPayload.self, from: directive.payload)
        guard case .attachment = payload.sourceType else {
            throw TTSError.notSupportedSourceType
        }
        
        header = directive.header
        internalPlayer = try OpusPlayer()
        internalPlayer?.delegate = self
    }
    
    func handleAttachment(_ attachment: Downstream.Attachment) -> Bool {
        guard let dataSource = internalPlayer as? MediaOpusStreamDataSource,
              header.dialogRequestId == attachment.header.dialogRequestId else {
            return false
        }
        
        do {
            try dataSource.appendData(attachment.content)
            
            if attachment.isEnd {
                try dataSource.lastDataAppended()
            }
        } catch {
            log.error(error)
            internalPlayer?.stop()
        }
        return true
    }
    
    func stop(reason: StopReason) -> Bool {
        guard let player = internalPlayer else { return false }
        if reason == .playAnother {
            cancelAssociation = false
            internalPlayer = nil
            player.delegate = nil
            delegate?.mediaPlayerStateDidChange(.stop, mediaPlayer: self)
        }
        player.stop()
        return true
    }
}

// MARK: - MediaPlayable

extension TTSPlayer: MediaPlayable {
    var offset: TimeIntervallic {
        return internalPlayer?.offset ?? NuguTimeInterval(seconds: 0)
    }
    
    var duration: TimeIntervallic {
        return internalPlayer?.duration ?? NuguTimeInterval(seconds: 0)
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

extension TTSPlayer: MediaPlayerDelegate {
    public func mediaPlayerStateDidChange(_ state: MediaPlayerState, mediaPlayer: MediaPlayable ) {
        log.info("media state: \(state)")
        
        switch state {
        case .finish, .stop, .error:
            internalPlayer = nil
        default:
            break
        }
        
        delegate?.mediaPlayerStateDidChange(state, mediaPlayer: self)
    }
    
    func mediaPlayerDurationDidChange(_ duration: TimeIntervallic, mediaPlayer: MediaPlayable) {
        delegate?.mediaPlayerDurationDidChange(duration, mediaPlayer: self)
    }
    
    func mediaPlayerChunkDidConsume(_ chunk: Data) {
        delegate?.mediaPlayerChunkDidConsume(chunk)
    }
}
