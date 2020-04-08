//
//  MediaPlayer.swift
//  NuguCore
//
//  Created by MinChul Lee on 22/04/2019.
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

public class MediaPlayer: MediaPlayable {
    public weak var delegate: MediaPlayerDelegate?
    
    private var player: AVQueuePlayer?
    private var playerItem: MediaAVPlayerItem?
    
    public init() {}
}

// MARK: - MediaPlayable

extension MediaPlayer {
    public func play() {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
                self.delegate?.mediaPlayerDidChange(state: .error(error: MediaPlayableError.notPrepareSource))
                return
        }
        
        mediaPlayer.play()
        
        delegate?.mediaPlayerDidChange(state: .start)
    }
    
    public func stop() {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
                self.delegate?.mediaPlayerDidChange(state: .error(error: MediaPlayableError.notPrepareSource))
                return
        }
        
        mediaPlayer.replaceCurrentItem(with: nil)
        playerItem?.delegate = nil  // CHECK-ME: 타이밍 이슈 없을지 확인
        
        playerItem = nil
        player = nil
        
        delegate?.mediaPlayerDidChange(state: .stop)
    }
    
    public func pause() {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
                self.delegate?.mediaPlayerDidChange(state: .error(error: MediaPlayableError.notPrepareSource))
                return
        }
        
        mediaPlayer.pause()
        
        delegate?.mediaPlayerDidChange(state: .pause)
    }
    
    public func resume() {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
                self.delegate?.mediaPlayerDidChange(state: .error(error: MediaPlayableError.notPrepareSource))
                return
        }
        
        mediaPlayer.play()
        
        delegate?.mediaPlayerDidChange(state: .resume)
    }
    
    public func seek(to offset: TimeIntervallic, completion: ((Result<Void, Error>) -> Void)?) {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
                completion?(.failure(MediaPlayableError.notPrepareSource))
                return
        }

        mediaPlayer.seek(to: offset.cmTime)
        completion?(.success(()))
    }
    
    public var offset: TimeIntervallic {
        guard let mediaPlayer = player else {
            log.warning("player is nil")
            return NuguTimeInterval(seconds: 0)
        }
        
        return mediaPlayer.currentTime()
    }
    
    public var duration: TimeIntervallic {
        guard let asset = player?.currentItem?.asset else {
            log.warning("player is nil")
            return NuguTimeInterval(seconds: 0)
        }
        
        return asset.duration
    }
    
    public var volume: Float {
        get {
            return player?.volume ?? 1.0
        }
        set {
            player?.volume = newValue
        }
    }
}

// MARK: - MediaPlayer + MediaUrlDataSource

extension MediaPlayer: MediaUrlDataSource {
    public func setSource(url: String, offset: TimeIntervallic) {
        guard let urlItem = URL(string: url) else {
            delegate?.mediaPlayerDidChange(state: .error(error: MediaPlayableError.invalidURL))
            return
        }
        
        setSource(url: urlItem, offset: offset)
    }
    
    public func setSource(url: URL, offset: TimeIntervallic) {
        playerItem = MediaAVPlayerItem(url: url)
        playerItem?.delegate = self
        player = AVQueuePlayer(playerItem: playerItem)
                
        if offset.seconds > 0 {
            player?.seek(to: offset.cmTime)
        }
    }
}

// MARK: - MediaAVPlayerItemDelegate

extension MediaPlayer: MediaAVPlayerItemDelegate {
    func mediaAVPlayerItem(_ playerItem: MediaAVPlayerItem,
                           didChangePlaybackStatus status: MediaAVPlayerItem.PlaybackStatus) {
        switch status {
        case .failed(let error):
            guard let playerItemError = error else {
                delegate?.mediaPlayerDidChange(state: .error(error: MediaPlayableError.unknown))
                break
            }
            
            delegate?.mediaPlayerDidChange(state: .error(error: playerItemError))
        default:
            break
        }
    }
    
    func mediaAVPlayerItem(_ playerItem: MediaAVPlayerItem,
                           didChangeBufferState status: MediaAVPlayerItem.BufferState) {
        delegate?.mediaPlayerDidChange(state: status.mediaPlayerState)
    }
    
    func mediaAVPlayerItemPlaybackStalled(_ playerItem: MediaAVPlayerItem) {
        //
    }
    
    func mediaAVPlayerItemDidPlayToEndTime(_ playerItem: MediaAVPlayerItem) {
        delegate?.mediaPlayerDidChange(state: .finish)
    }
}

// MARK: - MediaAVPlayerItem.BufferState + MediaPlayerState

private extension MediaAVPlayerItem.BufferState {
    var mediaPlayerState: MediaPlayerState {
        switch self {
        case .bufferFinished: return .bufferRefilled
        case .buffering: return .bufferUnderrun
        }
    }
}
