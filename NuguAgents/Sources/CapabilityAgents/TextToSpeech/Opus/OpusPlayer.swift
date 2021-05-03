//
//  OpusPlayer.swift
//  NuguAgents
//
//  Created by childc on 2020/05/06.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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
import SilverTray

/**
 SKT-OPUS player.
 
 NUGU-TTS server sends weired-formated opus data.
 
 Though opus codec couldn't encode/decode 22050 samples per sec. But they use that sample rate.
 Furthermore, They don't follow the RFC-6716(https://tools.ietf.org/html/rfc6716) packetizing.
 
 So, SDK needs to fix it to regular opus data.
 */
class OpusPlayer: MediaPlayable {
    private let player: DataStreamPlayer
    weak var delegate: MediaPlayerDelegate?
    
    init() throws {
        /*
         There's no 22050hz in opus world.
         So decode it as 24khz and play it slower.
         */
        try player = DataStreamPlayer(decoder: OpusDecoder(sampleRate: 24000.0, channels: 1))
        player.speed = 0.91875 // == 24000/22050
        player.delegate = self
    }
    
    var offset: TimeIntervallic {
        return NuguTimeInterval(milliseconds: player.offset)
    }
    
    var duration: TimeIntervallic {
        return NuguTimeInterval(milliseconds: player.duration)
    }
    
    var volume: Float {
        get {
            return player.volume
        }
        
        set {
            player.volume = newValue
        }
    }
    
    func play() {
        player.play()
    }

    func stop() {
        player.stop()
    }
    
    func pause() {
        player.pause()
    }
    
    func resume() {
        player.resume()
    }
    
    func seek(to offset: TimeIntervallic, completion: ((EndedUp<Error>) -> Void)? = nil) {
        player.seek(to: offset.truncatedMilliSeconds) { (result) in
            completion?(result.toEndedUp())
        }
    }
}

extension OpusPlayer: DataStreamPlayerDelegate {
    func dataStreamPlayerStateDidChange(_ state: DataStreamPlayerState) {
        var playerState: MediaPlayerState {
            switch state {
            case .start:
                return .start
            case .stop:
                return .stop
            case .pause:
                return .pause
            case .resume:
                return .resume
            case .finish:
                return .finish
            case .error(let error):
                return .error(error: error)
            default:
                return .error(error: MediaPlayableError.unknown)
            }
        }
        
        delegate?.mediaPlayerStateDidChange(playerState, mediaPlayer: self)
    }
}

extension OpusPlayer: MediaOpusStreamDataSource {
    func appendData(_ data: Data) throws {
        try SktOpusParser.parse(from: data).forEach { (chunk) in
            try player.appendData(chunk)
        }
    }
    
    func lastDataAppended() throws {
        try player.lastDataAppended()
    }
}
