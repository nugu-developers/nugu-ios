//
//  ControlCenterManager.swift
//  NuguClientKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2021/02/09.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
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
import MediaPlayer

import NuguAgents
import NuguUIKit

public final class ControlCenterManager {
    private var nowPlayingInfo: [String: Any] = [:] {
        didSet {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    private let nowPlayInfoCenterQueue = DispatchQueue(label: "com.sktelecom.romaine.now_playing_info_update_queue")
    
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var toggleCommandTarget: Any?
    private var previousCommandTarget: Any?
    private var nextCommandTarget: Any?
    private var seekCommandTarget: Any?
    
    private var mediaArtWorkDownloadDataTask: URLSessionDataTask?
    
    private let audioPlayerAgent: AudioPlayerAgentProtocol
    
    public init(audioPlayerAgent: AudioPlayerAgentProtocol) {
        self.audioPlayerAgent = audioPlayerAgent
    }
}

// MARK: - public (update)

public extension ControlCenterManager {
    func update(_ template: AudioPlayerDisplayTemplate) {
        nowPlayInfoCenterQueue.async { [weak self] in
            guard let self = self else { return }
            guard let parsedPayload = self.parsePayload(template: template) else {
                log.debug("invalid payload")
                return
            }
            
            // Set nowPlayingInfo display properties
            var nowPlayingInfoForUpdate = self.nowPlayingInfo
            nowPlayingInfoForUpdate[MPMediaItemPropertyTitle] = parsedPayload.title
            
            var artistString: String {
                let artist = parsedPayload.artist
                
                guard let albumTitle = parsedPayload.albumTitle else {
                    return artist
                }
                
                return artist + " - " + albumTitle
            }
            nowPlayingInfoForUpdate[MPMediaItemPropertyArtist] = artistString
            
            nowPlayingInfoForUpdate[MPNowPlayingInfoPropertyPlaybackRate] = self.audioPlayerAgent.isPlaying ? 1.0 : 0.0
            
            // Set song title and album title first. Because getting album art must be processed asynchronouly.
            self.nowPlayingInfo = nowPlayingInfoForUpdate
            
            // Set MPMediaItemArtwork if imageUrl exists
            self.mediaArtWorkDownloadDataTask?.cancel()
            if let imageUrl = parsedPayload.imageUrl, let artWorkUrl = URL(string: imageUrl) {
                self.mediaArtWorkDownloadDataTask = ImageDataLoader.shared.load(imageUrl: artWorkUrl) { [weak self] (result) in
                    guard case let .success(imageData) = result,
                          let artWorkImage = UIImage(data: imageData),
                          var nowPlayingInfoForUpdate = self?.nowPlayingInfo else {
                        self?.nowPlayingInfo[MPMediaItemPropertyArtwork] = nil
                        return
                    }
                    let artWork = MPMediaItemArtwork(boundsSize: artWorkImage.size) { _ in artWorkImage }
                    nowPlayingInfoForUpdate[MPMediaItemPropertyArtwork] = artWork
                    self?.nowPlayingInfo = nowPlayingInfoForUpdate
                }
            } else {
                self.nowPlayingInfo[MPMediaItemPropertyArtwork] = nil
            }
            self.addRemoteCommands(seekable: template.isSeekable)
        }
    }
    
    func update(_ state: AudioPlayerState) {
        nowPlayInfoCenterQueue.async { [weak self] in
            guard let self = self else { return }
            
            var nowPlayingInfoForUpdate = self.nowPlayingInfo
            
            switch state {
            case .playing:
                // Set playbackTime as current offset, set playbackRate as 1
                nowPlayingInfoForUpdate[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.audioPlayerAgent.offset ?? 0
                nowPlayingInfoForUpdate[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
                nowPlayingInfoForUpdate[MPMediaItemPropertyPlaybackDuration] = self.audioPlayerAgent.duration ?? 0
                
            case .paused:
                // Set playbackRate as 0, set playbackTime as current offset
                nowPlayingInfoForUpdate[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.audioPlayerAgent.offset ?? 0
                nowPlayingInfoForUpdate[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            default:
                // Set playbackRate as 0, set playbackTime as 0
                nowPlayingInfoForUpdate[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
                nowPlayingInfoForUpdate[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
                nowPlayingInfoForUpdate[MPMediaItemPropertyPlaybackDuration] = 0
            }
            
            if self.seekCommandTarget == nil {
                nowPlayingInfoForUpdate[MPMediaItemPropertyPlaybackDuration] = 0
            }
                        
            self.nowPlayingInfo = nowPlayingInfoForUpdate
        }
    }
    
    func update(_ duration: Int) {
        nowPlayInfoCenterQueue.async { [weak self] in
            guard let self = self else { return }

            var nowPlayingInfoForUpdate = self.nowPlayingInfo
            nowPlayingInfoForUpdate[MPMediaItemPropertyPlaybackDuration] = (self.seekCommandTarget != nil) ? duration : 0
            
            self.nowPlayingInfo = nowPlayingInfoForUpdate
        }
    }
    
    func remove() {
        nowPlayInfoCenterQueue.async { [weak self] in
            self?.mediaArtWorkDownloadDataTask?.cancel()
            self?.removeRemoteCommands()
            self?.nowPlayingInfo = [:]
        }
    }
}

// MARK: - MPNowPlayingInfoCenter

private extension ControlCenterManager {
    func addRemoteCommands(seekable isSeekable: Bool) {
        // These commands below will be sent from a wireless earset.
        addPlayCommand()
        addPauseCommand()
        
        // Toggle command will be sent from a hard wired earset.
        addTogglePlayPauseComand()
        
        // These commands below will be sent from wired and wireless earset both.
        addPreviousTrackCommand()
        addNextTackCommand()
        
        if isSeekable {
            addChangePlaybackPositionCommand()
        } else {
            removeChangePlaybackPositionCommand()
        }
    }
    
    func removeRemoteCommands() {
        removePlayCommand()
        removePauseCommand()
        removeTogglePlayPauseCommand()
        removePreviousTrackCommand()
        removeNextTrackCommand()
        removeChangePlaybackPositionCommand()
    }
    
    func parsePayload(template: AudioPlayerDisplayTemplate) -> (title: String, artist: String, albumTitle: String?, imageUrl: String?)? {
        guard let payloadAsData = try? JSONSerialization.data(withJSONObject: template.payload, options: []) else {
            return nil
        }
        switch template.type {
        case "AudioPlayer.Template1":
            guard let payload = try? JSONDecoder().decode(AudioPlayer1Template.self, from: payloadAsData) else {
                remove()
                return nil
            }
            return (payload.template.content.title, payload.template.content.subtitle1, payload.template.content.subtitle2, payload.template.content.imageUrl)
        default:
            remove()
            return nil
        }
    }
}

// MARK: - Private (MPRemoteCommandCenter.Command)

private extension ControlCenterManager {
    
    // MARK: Add Commands
    
    func addPlayCommand() {
        guard playCommandTarget == nil else { return }
        
        if playCommandTarget == nil {
            playCommandTarget = remoteCommandCenter
                .playCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
                    self?.audioPlayerAgent.play()
                    return .success
            }
        }
    }
    
    func addPauseCommand() {
        guard pauseCommandTarget == nil else { return }
        
        pauseCommandTarget = remoteCommandCenter
            .pauseCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
                self?.audioPlayerAgent.pause()
                return .success
        }
    }
    
    func addTogglePlayPauseComand() {
        toggleCommandTarget = remoteCommandCenter
            .togglePlayPauseCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
                guard let self = self else { return .commandFailed }
                self.audioPlayerAgent.isPlaying ? self.audioPlayerAgent.pause() : self.audioPlayerAgent.play()
                return .success
            }
    }
    
    func addPreviousTrackCommand() {
        guard previousCommandTarget == nil else { return }
        
        previousCommandTarget = remoteCommandCenter
            .previousTrackCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
                self?.audioPlayerAgent.prev()
                return .success
        }
    }
    
    func addNextTackCommand() {
        guard nextCommandTarget == nil else { return }
        
        nextCommandTarget = remoteCommandCenter
            .nextTrackCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
                self?.audioPlayerAgent.next()
                return .success
        }
    }
    
    func addChangePlaybackPositionCommand() {
        guard seekCommandTarget == nil else { return }
        
        seekCommandTarget = remoteCommandCenter
            .changePlaybackPositionCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
                guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
                self?.audioPlayerAgent.seek(to: Int(event.positionTime))
                return .success
        }
    }
    
    // MARK: Remove Commands
    
    func removePlayCommand() {
        remoteCommandCenter.playCommand.removeTarget(playCommandTarget)
        playCommandTarget = nil
    }
    
    func removePauseCommand() {
        remoteCommandCenter.pauseCommand.removeTarget(pauseCommandTarget)
        pauseCommandTarget = nil
    }
    
    func removeTogglePlayPauseCommand() {
        remoteCommandCenter.togglePlayPauseCommand.removeTarget(toggleCommandTarget)
        toggleCommandTarget = nil
    }
    
    func removePreviousTrackCommand() {
        remoteCommandCenter.previousTrackCommand.removeTarget(previousCommandTarget)
        previousCommandTarget = nil
    }
    
    func removeNextTrackCommand() {
        remoteCommandCenter.nextTrackCommand.removeTarget(nextCommandTarget)
        nextCommandTarget = nil
    }
    
    func removeChangePlaybackPositionCommand() {
        remoteCommandCenter.changePlaybackPositionCommand.removeTarget(seekCommandTarget)
        seekCommandTarget = nil
    }
}
