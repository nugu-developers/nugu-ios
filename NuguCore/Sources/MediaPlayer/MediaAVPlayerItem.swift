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
        removePlayerItemObservers()
        removeNotificationObservers()
    }
    
    // AVPlayer has a bug when using the new block based KVO API
    // swiftlint:disable block_based_kvo
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard context == &MediaAVPlayerItem.observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switch keyPath {
        case #keyPath(AVPlayerItem.status):
            guard
                let statusRawValue = change?[.newKey] as? Int,
                let status = AVPlayerItem.Status(rawValue: statusRawValue) else {
                    log.info("playback status changed: (Type) Unknown")
                    delegate?.mediaAVPlayerItem(self, didChangePlaybackStatus: .unknown)
                    break
            }
            
            log.debug("playback status changed: \(status)")
            
            switch status {
            case .readyToPlay:
                delegate?.mediaAVPlayerItem(self, didChangePlaybackStatus: .readyToPlay)
            case .failed:
                log.debug("playback failed reason: \(String(describing: error))")
                delegate?.mediaAVPlayerItem(self, didChangePlaybackStatus: .failed(error: error))
            default: //Contains unknown
                delegate?.mediaAVPlayerItem(self, didChangePlaybackStatus: .unknown)
            }
        case #keyPath(isPlaybackBufferEmpty):
            guard
                let isBufferEmpty = change?[.newKey] as? Bool,
                isBufferEmpty == true else {
                    break
            }
            
            log.debug("BufferEmpty")
            
            delegate?.mediaAVPlayerItem(self, didChangeBufferState: .buffering)
        case #keyPath(isPlaybackLikelyToKeepUp):
            guard
                let isLikelyToKeepUp = change?[.newKey] as? Bool,
                isLikelyToKeepUp == true else {
                    break
            }
            
            log.debug("LikelyToKeepUp")
            
            delegate?.mediaAVPlayerItem(self, didChangeBufferState: .bufferFinished)
        case #keyPath(isPlaybackBufferFull):
            guard
                let isBufferFull = change?[.newKey] as? Bool,
                isBufferFull == true else {
                    break
            }
            
            log.debug("BufferFull")
            
            delegate?.mediaAVPlayerItem(self, didChangeBufferState: .bufferFinished)
        default:
            break
        }
    }
    // swiftlint:enable block_based_kvo
}

// MARK: - KVO Observers

private extension MediaAVPlayerItem {
    func addPlayerItemObservers() {
        addObserver(self,
                    forKeyPath: #keyPath(AVPlayerItem.status),
                    options: [.initial, .new],
                    context: &MediaAVPlayerItem.observerContext)
        
        addObserver(self,
                    forKeyPath: #keyPath(isPlaybackBufferEmpty),
                    options: [.initial, .new],
                    context: &MediaAVPlayerItem.observerContext)
        
        addObserver(self,
                    forKeyPath: #keyPath(isPlaybackLikelyToKeepUp),
                    options: [.initial, .new],
                    context: &MediaAVPlayerItem.observerContext)
        
        addObserver(self,
                    forKeyPath: #keyPath(isPlaybackBufferFull),
                    options: [.initial, .new],
                    context: &MediaAVPlayerItem.observerContext)
    }
    
    func removePlayerItemObservers() {
        removeObserver(self,
                       forKeyPath: #keyPath(status),
                       context: &MediaAVPlayerItem.observerContext)
        
        removeObserver(self,
                       forKeyPath: #keyPath(isPlaybackBufferEmpty),
                       context: &MediaAVPlayerItem.observerContext)
        
        removeObserver(self,
                       forKeyPath: #keyPath(isPlaybackLikelyToKeepUp),
                       context: &MediaAVPlayerItem.observerContext)
        
        removeObserver(self,
                       forKeyPath: #keyPath(isPlaybackBufferFull),
                       context: &MediaAVPlayerItem.observerContext)
    }
}

// MARK: - Notification Observers

private extension MediaAVPlayerItem {
    func addNotificationObservers() {
        playToEndTimeObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil, using: { [weak self] _ in
            log.debug("Did play to end time")
            guard let self = self else { return }
            
            self.delegate?.mediaAVPlayerItemDidPlayToEndTime(self)
        })
        
        playbackStalledObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemPlaybackStalled, object: nil, queue: nil, using: { [weak self] _ in
            log.debug("Playback Stalled")
            guard let self = self else { return }
            
            self.delegate?.mediaAVPlayerItemPlaybackStalled(self)
        })
        
        // Maybe called by network issue
        failedToPlayEndTimeObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: nil, queue: nil, using: { [weak self] notification in
            log.debug("Failed to play end time")
            guard let self = self else { return }
            
            let failedToPlayToEndTimeError = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            log.info("playerItem failed to play to endTime, reason: \(String(describing: failedToPlayToEndTimeError))")
            
            // CHECK-ME: Failed State로 주는게 맞을지 검토 필요
            self.delegate?.mediaAVPlayerItem(self, didChangePlaybackStatus: .failed(error: failedToPlayToEndTimeError))
        })
        
        newErrorLogEntryObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemNewErrorLogEntry, object: nil, queue: nil, using: { [weak self] _ in
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
