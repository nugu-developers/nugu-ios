//
//  NuguDisplayPlayerController.swift
//  SampleApp
//
//  Created by yonghoonKwon on 02/08/2019.
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
import MediaPlayer

import NuguAgents
import NuguUIKit

final class NuguDisplayPlayerController {
    private var nowPlayingInfo: [String: Any] = [:] {
        didSet {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    private let nowPlayInfoCenterQueue = DispatchQueue(label: "com.sktelecom.romaine.now_playing_info_update_queue")
    
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var toggleCommandTarget: Any?
    private var previousCommandTarget: Any?
    private var nextCommandTarget: Any?
    private var seekCommandTarget: Any?
    
    private var mediaArtWorkDownloadDataTask: URLSessionDataTask?
    
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
            nowPlayingInfoForUpdate[MPMediaItemPropertyAlbumTitle] = parsedPayload.albumTitle
            
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
                nowPlayingInfoForUpdate[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NuguCentralManager.shared.client.audioPlayerAgent.offset ?? 0
                nowPlayingInfoForUpdate[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
                nowPlayingInfoForUpdate[MPMediaItemPropertyPlaybackDuration] = NuguCentralManager.shared.client.audioPlayerAgent.duration ?? 0
                
            case .paused:
                // Set playbackRate as 0, set playbackTime as current offset
                nowPlayingInfoForUpdate[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NuguCentralManager.shared.client.audioPlayerAgent.offset ?? 0
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

private extension NuguDisplayPlayerController {
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
    
    func parsePayload(template: AudioPlayerDisplayTemplate) -> (title: String, albumTitle: String, imageUrl: String?)? {
        guard let payloadAsData = try? JSONSerialization.data(withJSONObject: template.payload, options: []) else {
            return nil
        }
        switch template.type {
        case "AudioPlayer.Template1":
            guard let payload = try? JSONDecoder().decode(AudioPlayer1Template.self, from: payloadAsData) else {
                remove()
                return nil
            }
            return (payload.template.title.text, payload.template.content.title, payload.template.content.imageUrl)
        case "AudioPlayer.Template2":
            guard let payload = try? JSONDecoder().decode(AudioPlayer2Template.self, from: payloadAsData) else {
                remove()
                return nil
            }
            return (payload.template.title.text, payload.template.content.title, payload.template.content.imageUrl)
        default:
            remove()
            return nil
        }
    }
}

// MARK: - Private (MPRemoteCommandCenter.Command)

private extension NuguDisplayPlayerController {
    
    // MARK: Add Commands
    
    func addPlayCommand() {
        guard playCommandTarget == nil else { return }
        
        if playCommandTarget == nil {
            playCommandTarget = remoteCommandCenter
                .playCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                    NuguCentralManager.shared.client.audioPlayerAgent.play()
                    return .success
            }
        }
    }
    
    func addPauseCommand() {
        guard pauseCommandTarget == nil else { return }
        
        pauseCommandTarget = remoteCommandCenter
            .pauseCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                NuguCentralManager.shared.client.audioPlayerAgent.pause()
                return .success
        }
    }
    
    func addTogglePlayPauseComand() {
        toggleCommandTarget = remoteCommandCenter
            .togglePlayPauseCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                let audioPlayerAgent = NuguCentralManager.shared.client.audioPlayerAgent
                audioPlayerAgent.isPlaying ? audioPlayerAgent.pause() : audioPlayerAgent.play()
                return .success
            }
    }
    
    func addPreviousTrackCommand() {
        guard previousCommandTarget == nil else { return }
        
        previousCommandTarget = remoteCommandCenter
            .previousTrackCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                NuguCentralManager.shared.client.audioPlayerAgent.prev()
                return .success
        }
    }
    
    func addNextTackCommand() {
        guard nextCommandTarget == nil else { return }
        
        nextCommandTarget = remoteCommandCenter
            .nextTrackCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                NuguCentralManager.shared.client.audioPlayerAgent.next()
                return .success
        }
    }
    
    func addChangePlaybackPositionCommand() {
        guard seekCommandTarget == nil else { return }
        
        seekCommandTarget = remoteCommandCenter
            .changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
                guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
                NuguCentralManager.shared.client.audioPlayerAgent.seek(to: Int(event.positionTime))
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
