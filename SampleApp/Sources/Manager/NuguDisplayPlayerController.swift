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
import NuguClientKit
import NuguUIKit

final class NuguDisplayPlayerController {
    
    // MARK: Properties
    
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    private var previousCommandTarget: Any?
    private var nextCommandTarget: Any?
    private var seekCommandTarget: Any?
    
    private var currentItem: AudioPlayerDisplayTemplate?
    private var currentState: AudioPlayerState = .idle
    private var nowPlayingInfoCenter: MPNowPlayingInfoCenter?
    
    private var renderingContext: AnyObject?
    private var albumImageLoadRequest: URLSessionDataTask?
        
    init() {
        update()
    }
    
    func nuguAudioPlayerDisplayDidRender(template: AudioPlayerDisplayTemplate) {
        DispatchQueue.main.async { [weak self] in
            self?.update(newItem: template)
        }
    }
    
    func nuguAudioPlayerDisplayDidClear() {
        DispatchQueue.main.async { [weak self] in
            self?.remove()
        }
    }
    
    func nuguAudioPlayerAgentDidChange(state: AudioPlayerState) {
        DispatchQueue.main.async { [weak self] in
            self?.update(newState: state)
        }
    }
    
    func nuguAudioPlayerAgentDidChange(duration: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.update()
        }
    }
    
    func remove() {
        removeRemoteCommands()
        currentItem = nil
        nowPlayingInfoCenter?.nowPlayingInfo = nil
        nowPlayingInfoCenter = nil
        renderingContext = nil
    }
}

// MARK: - MPNowPlayingInfoCenter

private extension NuguDisplayPlayerController {
    func addRemoteCommands() {
        addPlayCommand()
        addPauseCommand()
        addPreviousTrackCommand()
        addNextTackCommand()
        if currentItem?.isSeekable == true {
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
    
    func update(
        newItem: AudioPlayerDisplayTemplate? = nil,
        newState: AudioPlayerState? = nil
        ) {
        let item = newItem ?? currentItem
        let state = newState ?? currentState
        
        defer {
            currentItem = item
            currentState = state
        }
        
        guard let playerItem = item else {
            remove()
            return
        }
        
        guard let parsedPayload = parsePayload(template: playerItem) else {
            log.debug("invalid payload")
            return
        }
        
        nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        if nowPlayingInfoCenter?.nowPlayingInfo == nil {
            nowPlayingInfoCenter?.nowPlayingInfo = [:]
        }
        
        nowPlayingInfoCenter?.nowPlayingInfo?[MPMediaItemPropertyTitle] = parsedPayload.title
        nowPlayingInfoCenter?.nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] = parsedPayload.albumTitle
        nowPlayingInfoCenter?.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = currentItem?.isSeekable == true ? (NuguCentralManager.shared.client.audioPlayerAgent.duration ?? 0) : 0
    
        addRemoteCommands()
        
        let offset = currentItem?.isSeekable == true ? (NuguCentralManager.shared.client.audioPlayerAgent.offset ?? 0) : 0
        
        switch state {
        case .playing:
            // Set playbackTime as current offset, set playbackRate as 1
            nowPlayingInfoCenter?.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = offset
            nowPlayingInfoCenter?.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        case .paused:
            // Set playbackRate as 0, set playbackTime as current offset
            nowPlayingInfoCenter?.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = offset
            nowPlayingInfoCenter?.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        default:
            // Set playbackRate as 0, set playbackTime as 0
            nowPlayingInfoCenter?.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
            nowPlayingInfoCenter?.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        }
        
        if let imageUrl = parsedPayload.imageUrl, let artWorkUrl = URL(string: imageUrl) {
            albumImageLoadRequest?.cancel()
            albumImageLoadRequest = ImageDataLoader.shared.load(imageUrl: artWorkUrl) { [weak self] (result) in
                switch result {
                case .success(let imageData):
                    guard let artWorkImage = UIImage(data: imageData) else {
                        self?.nowPlayingInfoCenter?.nowPlayingInfo?[MPMediaItemPropertyArtwork] = nil
                        return
                    }
                    let artWork = MPMediaItemArtwork(boundsSize: artWorkImage.size, requestHandler: { _ -> UIImage in
                        return artWorkImage
                    })
                    self?.nowPlayingInfoCenter?.nowPlayingInfo?[MPMediaItemPropertyArtwork] = artWork
                case .failure:
                    self?.nowPlayingInfoCenter?.nowPlayingInfo?[MPMediaItemPropertyArtwork] = nil
                }
            }
        } else {
            nowPlayingInfoCenter?.nowPlayingInfo?[MPMediaItemPropertyArtwork] = nil
        }
    }
}

// MARK: - Private (MPRemoteCommandCenter.Command)

private extension NuguDisplayPlayerController {
    
    // MARK: Add Commands
    
    func addPlayCommand() {
        guard playCommandTarget == nil else { return }
        
        if playCommandTarget == nil {
            playCommandTarget = MPRemoteCommandCenter.shared()
                .playCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                    NuguCentralManager.shared.client.audioPlayerAgent.play()
                    return .success
            }
        }
    }
    
    func addPauseCommand() {
        guard pauseCommandTarget == nil else { return }
        
        pauseCommandTarget = MPRemoteCommandCenter.shared()
            .pauseCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                NuguCentralManager.shared.client.audioPlayerAgent.pause()
                return .success
        }
    }
    
    func addPreviousTrackCommand() {
        guard previousCommandTarget == nil else { return }
        
        previousCommandTarget = MPRemoteCommandCenter.shared()
            .previousTrackCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                NuguCentralManager.shared.client.audioPlayerAgent.prev()
                return .success
        }
    }
    
    func addNextTackCommand() {
        guard nextCommandTarget == nil else { return }
        
        nextCommandTarget = MPRemoteCommandCenter.shared()
            .nextTrackCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                NuguCentralManager.shared.client.audioPlayerAgent.next()
                return .success
        }
    }
    
    func addChangePlaybackPositionCommand() {
        guard seekCommandTarget == nil else { return }
        
        seekCommandTarget = MPRemoteCommandCenter.shared()
            .changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
                guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
                NuguCentralManager.shared.client.audioPlayerAgent.seek(to: Int(event.positionTime))
                return .success
        }
    }
    
    // MARK: Remove Commands
    
    func removePlayCommand() {
        MPRemoteCommandCenter.shared().playCommand.removeTarget(playCommandTarget)
        playCommandTarget = nil
    }
    
    func removePauseCommand() {
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(pauseCommandTarget)
        pauseCommandTarget = nil
    }
    
    func removePreviousTrackCommand() {
        MPRemoteCommandCenter.shared().previousTrackCommand.removeTarget(previousCommandTarget)
        previousCommandTarget = nil
    }
    
    func removeNextTrackCommand() {
        MPRemoteCommandCenter.shared().nextTrackCommand.removeTarget(nextCommandTarget)
        nextCommandTarget = nil
    }
    
    func removeChangePlaybackPositionCommand() {
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.removeTarget(seekCommandTarget)
        seekCommandTarget = nil
    }
}
