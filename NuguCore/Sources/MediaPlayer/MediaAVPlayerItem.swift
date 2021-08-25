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

import NuguUtils

// MARK: - MediaAVPlayerItem

final class MediaAVPlayerItem: AVPlayerItem, TypedNotifyable {
    var cacheKey: String?
    
    // Observers
    private static var observerContext: Int = 0
    private let notificationCenter = NotificationCenter.default
    
    convenience init(url: URL, automaticallyLoadedAssetKeys: [String]? = nil) {
        self.init(
            asset: AVAsset(url: url),
            automaticallyLoadedAssetKeys: automaticallyLoadedAssetKeys
        )
    }
    
    convenience init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]? = nil, cacheKey: String) {
        self.init(
            asset: asset,
            automaticallyLoadedAssetKeys: automaticallyLoadedAssetKeys
        )
        
        self.cacheKey = cacheKey
    }
    
    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        super.init(
            asset: asset,
            automaticallyLoadedAssetKeys: automaticallyLoadedAssetKeys
        )
        
        addPlayerItemObservers()
    }
    
    deinit {
        removePlayerItemObservers()
    }
    
    // CAUTION!!!!!!
    // AVPlayer has a bug when using the new block based KVO API (especially iOS 13)
    // So we make notifier to use easily.
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
            guard let statusRawValue = change?[.newKey] as? Int,
                  let status = AVPlayerItem.Status(rawValue: statusRawValue) else {
                log.info("playback status changed: (Type) Unknown")
                post(NuguCoreNotification.MediaPlayerItem.PlaybackStatus.unknown)
                break
            }
            
            log.debug("playback status changed: \(status)")
            
            switch status {
            case .readyToPlay:
                post(NuguCoreNotification.MediaPlayerItem.PlaybackStatus.readyToPlay)
            case .failed:
                log.debug("playback failed reason: \(String(describing: error))")
                post(NuguCoreNotification.MediaPlayerItem.PlaybackStatus.failed(error: error))
            default: // Contains unknown
                post(NuguCoreNotification.MediaPlayerItem.PlaybackStatus.unknown)
            }
        case #keyPath(isPlaybackBufferEmpty):
            guard let isBufferEmpty = change?[.newKey] as? Bool,
                  isBufferEmpty == true else {
                break
            }
            
            log.debug("BufferEmpty")
            post(NuguCoreNotification.MediaPlayerItem.BufferStatus.bufferEmpty)
        case #keyPath(isPlaybackLikelyToKeepUp):
            guard let isLikelyToKeepUp = change?[.newKey] as? Bool,
                  isLikelyToKeepUp == true else {
                break
            }
            
            log.debug("LikelyToKeepUp")
            post(NuguCoreNotification.MediaPlayerItem.BufferStatus.likelyToKeepUp)
        default:
            break
        }
    }
    // swiftlint:enable block_based_kvo
}

// MARK: - KVO

private extension MediaAVPlayerItem {
    func addPlayerItemObservers() {
        addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: [.initial, .new],
            context: &MediaAVPlayerItem.observerContext
        )
        
        addObserver(
            self,
            forKeyPath: #keyPath(isPlaybackBufferEmpty),
            options: [.initial, .new],
            context: &MediaAVPlayerItem.observerContext
        )
        
        addObserver(
            self,
            forKeyPath: #keyPath(isPlaybackLikelyToKeepUp),
            options: [.initial, .new],
            context: &MediaAVPlayerItem.observerContext
        )
    }
    
    func removePlayerItemObservers() {
        removeObserver(
            self,
            forKeyPath: #keyPath(status),
            context: &MediaAVPlayerItem.observerContext
        )
        
        removeObserver(
            self,
            forKeyPath: #keyPath(isPlaybackBufferEmpty),
            context: &MediaAVPlayerItem.observerContext
        )
        
        removeObserver(
            self,
            forKeyPath: #keyPath(isPlaybackLikelyToKeepUp),
            context: &MediaAVPlayerItem.observerContext
        )
    }
}

// MARK: - Notification Observer

extension Notification.Name {
    static let mediaAVPlayerItemPlaybackStatus = Notification.Name("com.sktelecom.romaine.notification.name.media_avplayer_item_status")
    static let mediaAVPlayerItemBufferStatus = Notification.Name("com.sktelecom.romaine.notification.name.media_avplayer_buffer_status")
}

public extension NuguCoreNotification {
    enum MediaPlayerItem {
        public enum PlaybackStatus: EnumTypedNotification {
            public static let name: Notification.Name = .mediaAVPlayerItemPlaybackStatus
            
            case readyToPlay
            case failed(error: Error?)
            case unknown
        }
        
        public enum BufferStatus: EnumTypedNotification {
            public static let name: Notification.Name = .mediaAVPlayerItemBufferStatus
            
            case bufferEmpty
            case likelyToKeepUp
        }
    }
}
