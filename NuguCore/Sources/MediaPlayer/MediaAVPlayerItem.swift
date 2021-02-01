//
//  MediaAVPlayerItem.swift
//  NuguCore
//
//  Created by yonghoonKwon on 09/05/2019.
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

// MARK: - MediaAVPlayerItem

final class MediaAVPlayerItem: AVPlayerItem {
    var playToEndTimeObserver: Any?
    var playbackStalledObserver: Any?
    var failedToPlayEndTimeObserver: Any?
    var newErrorLogEntryObserver: Any?
    
    var playerStatusObserver: NSKeyValueObservation?
    var playbackBufferEmptyObserver: NSKeyValueObservation?
    var playbackLikelyToKeepUpObserver: NSKeyValueObservation?
    var playbackBufferFullObserver: NSKeyValueObservation?
    
    // MARK: AVPlayerItem's Buffer State
    
    enum BufferState {
        case buffering
        case bufferFinished
    }
    
    // MARK: AVPlayerItem's Playback State
    
    enum PlaybackStatus {
        case readyToPlay
        case failed(error: Error?)
        case unknown
    }
    
    private static var observerContext: Int = 0
    weak var delegate: MediaAVPlayerItemDelegate?
    
    var cacheKey: String?
    
    init(url: URL, automaticallyLoadedAssetKeys: [String]? = nil) {
        super.init(asset: AVAsset(url: url),
                   automaticallyLoadedAssetKeys: automaticallyLoadedAssetKeys)
        
        addPlayerItemObservers()
        addNotificationObservers()
    }
    
    init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]? = nil, cacheKey: String) {
        super.init(asset: asset,
                   automaticallyLoadedAssetKeys: automaticallyLoadedAssetKeys)
        self.cacheKey = cacheKey
        addPlayerItemObservers()
        addNotificationObservers()
    }
    
    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        super.init(asset: asset,
                   automaticallyLoadedAssetKeys: automaticallyLoadedAssetKeys)
        addPlayerItemObservers()
        addNotificationObservers()
    }
    
    deinit {
        removeNotificationObservers()
    }
}

// MARK: - KVO Observers

private extension MediaAVPlayerItem {
    func addPlayerItemObservers() {
        playerStatusObserver = observe(\.status, options: .new) { [weak self] (_, change) in
            guard let self = self else { return }
            guard change.oldValue != change.newValue else { return } // This closure will be called on iOS 12. Though old and new value are nil.

            log.debug("playback status changed: \(change.oldValue.debugDescription) -> \(change.newValue.debugDescription)")
            switch change.newValue {
            case .readyToPlay:
                self.delegate?.mediaAVPlayerItem(self, didChangePlaybackStatus: .readyToPlay)
            case .failed:
                log.debug("playback failed reason: \(self.error.debugDescription)")
                self.delegate?.mediaAVPlayerItem(self, didChangePlaybackStatus: .failed(error: self.error))
            default: //Contains unknown
                self.delegate?.mediaAVPlayerItem(self, didChangePlaybackStatus: .unknown)
            }
        }
        
        playbackBufferEmptyObserver = observe(\.isPlaybackBufferEmpty, options: .new, changeHandler: { [weak self] (_, change) in
            guard let self = self else { return }
            guard change.oldValue != change.newValue else { return }

            log.debug("isBufferEmpty: \(change.oldValue.debugDescription) --> \(change.newValue.debugDescription)")
            if change.newValue == true {
                self.delegate?.mediaAVPlayerItem(self, didChangeBufferState: .buffering)
            }
        })
        
        playbackLikelyToKeepUpObserver = observe(\.isPlaybackLikelyToKeepUp, options: .new, changeHandler: { [weak self] (_, change) in
            guard let self = self else { return }
            guard change.oldValue != change.newValue else { return }
            
            log.debug("isLikelyToKeepUp: \(change.oldValue.debugDescription) -> \(change.newValue.debugDescription)")
            if change.newValue == true {
                self.delegate?.mediaAVPlayerItem(self, didChangeBufferState: .bufferFinished)
            }
        })
        
        playbackBufferFullObserver = observe(\.isPlaybackBufferFull, options: .new, changeHandler: { [weak self] (_, change) in
            guard let self = self else { return }
            guard change.oldValue != change.newValue else { return }
            
            log.debug("isBufferFull: \(change.oldValue.debugDescription) -> \(change.newValue.debugDescription)")
            if change.newValue == true {
                self.delegate?.mediaAVPlayerItem(self, didChangeBufferState: .bufferFinished)
            }
        })
    }
}

// MARK: - Notification Observers

private extension MediaAVPlayerItem {
    func addNotificationObservers() {
        playToEndTimeObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self, queue: nil, using: { [weak self] _ in
            log.debug("Did play to end time")
            guard let self = self else { return }
            
            self.delegate?.mediaAVPlayerItemDidPlayToEndTime(self)
        })
        
        playbackStalledObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemPlaybackStalled, object: self, queue: nil, using: { [weak self] _ in
            log.debug("Playback Stalled")
            guard let self = self else { return }
            
            self.delegate?.mediaAVPlayerItemPlaybackStalled(self)
        })
        
        // Maybe called by network issue
        failedToPlayEndTimeObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: self, queue: nil, using: { [weak self] notification in
            log.debug("Failed to play end time")
            guard let self = self else { return }
            
            let failedToPlayToEndTimeError = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            log.info("playerItem failed to play to endTime, reason: \(String(describing: failedToPlayToEndTimeError))")
            
            // CHECK-ME: Failed State로 주는게 맞을지 검토 필요
            self.delegate?.mediaAVPlayerItem(self, didChangePlaybackStatus: .failed(error: failedToPlayToEndTimeError))
        })
        
        newErrorLogEntryObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemNewErrorLogEntry, object: self, queue: nil, using: { [weak self] _ in
            // CHECK-ME: errorLog 잘 출력되는지 확인 필요
            log.info("playerItem has new error log: \(String(describing: self?.errorLog()))")
        })
    }
    
    func removeNotificationObservers() {
        if let playToEndTimeObserver = playToEndTimeObserver {
            NotificationCenter.default.removeObserver(playToEndTimeObserver)
            self.playToEndTimeObserver = nil
        }
        
        if let playbackStalledObserver = playbackStalledObserver {
            NotificationCenter.default.removeObserver(playbackStalledObserver)
            self.playbackStalledObserver = nil
        }
        
        if let failedToPlayEndTimeObserver = failedToPlayEndTimeObserver {
            NotificationCenter.default.removeObserver(failedToPlayEndTimeObserver)
            self.failedToPlayEndTimeObserver = nil
        }
        
        if let newErrorLogEntryObserver = newErrorLogEntryObserver {
            NotificationCenter.default.removeObserver(newErrorLogEntryObserver)
            self.newErrorLogEntryObserver = nil
        }
    }
}

// MARK: - AVPlayerItem.Status extension

extension AVPlayerItem.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "failed"
        default:
            return "unknown"
        }
    }
}
