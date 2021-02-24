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

final public class ControlCenterManager {
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    private let nowPlayInfoCenterQueue = DispatchQueue(label: "com.sktelecom.romaine.now_playing_info_update_queue")
    
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var previousCommandTarget: Any?
    private var nextCommandTarget: Any?
    private var seekCommandTarget: Any?
    
    private let audioPlayerAgent: AudioPlayerAgentProtocol
    
    public init(audioPlayerAgent: AudioPlayerAgentProtocol) {
        self.audioPlayerAgent = audioPlayerAgent
    }
}

public extension ControlCenterManager {
    func update(_ template: AudioPlayerDisplayTemplate) {
        nowPlayInfoCenterQueue.async { [weak self] in
            guard let self = self else { return }
            guard let parsedPayload = self.parsePayload(template: template) else {
                log.debug("invalid payload")
                return
            }
            
            // Set nowPlayingInfo display properties
            var nowPlayingInfo = self.nowPlayingInfoCenter.nowPlayingInfo ?? [:]
            nowPlayingInfo[MPMediaItemPropertyTitle] = parsedPayload.title
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = parsedPayload.albumTitle
            
            // Set song title and album title first. Because getting album art must be processed asynchronouly.
            self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
            
            // Set MPMediaItemArtwork if imageUrl exists
            if let imageUrl = parsedPayload.imageUrl, let artWorkUrl = URL(string: imageUrl) {
                ImageDataLoader.shared.load(imageUrl: artWorkUrl) { [weak self] (result) in
                    guard case let .success(imageData) = result,
                          let artWorkImage = UIImage(data: imageData) else {
                        self?.nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] = nil
                        return
                    }

                    let artWork = MPMediaItemArtwork(boundsSize: artWorkImage.size) { _ in artWorkImage }
                    var playingInfo = self?.nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
                    playingInfo[MPMediaItemPropertyArtwork] = artWork
                    self?.nowPlayingInfoCenter.nowPlayingInfo = playingInfo
                }
            } else {
                self.nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] = nil
            }
            self.addRemoteCommands(seekable: template.isSeekable)
        }
    }
    
    func update(_ state: AudioPlayerState) {
        nowPlayInfoCenterQueue.async { [weak self] in
            guard let self = self else { return }
            
            var nowPlayingInfo = self.nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
            
            switch state {
            case .playing:
                // Set playbackTime as current offset, set playbackRate as 1
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.audioPlayerAgent.offset ?? 0
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.audioPlayerAgent.duration ?? 0
                
            case .paused:
                // Set playbackRate as 0, set playbackTime as current offset
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.audioPlayerAgent.offset ?? 0
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            default:
                // Set playbackRate as 0, set playbackTime as 0
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0
            }
            
            if self.seekCommandTarget == nil {
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0
            }
            
            self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }
    
    func update(_ duration: Int) {
        nowPlayInfoCenterQueue.async { [weak self] in
            guard let self = self else { return }

            var nowPlayingInfo = self.nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = (self.seekCommandTarget != nil) ? duration : 0
            
            self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }
    
    func remove() {
        nowPlayInfoCenterQueue.async { [weak self] in
            self?.removeRemoteCommands()
            self?.nowPlayingInfoCenter.nowPlayingInfo = nil
        }
    }
}

// MARK: - MPNowPlayingInfoCenter

private extension ControlCenterManager {
    func addRemoteCommands(seekable isSeekable: Bool) {
        addPlayCommand()
        addPauseCommand()
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
