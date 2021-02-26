//
//  ASRBeepPlayer.swift
//  NuguClientKit
//
//  Created by jin kim on 2019/12/09.
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

import AVFoundation

import NuguCore

final class ASRBeepPlayer {
    static var isStartBeepEnabled: Bool = true
    static var isSuccessBeepEnabled: Bool = true
    static var isFailBeepEnabled: Bool = true
    
    static var resourcesUrl: ASRBeepPlayerResourcesURL!
    
    private let focusManager: FocusManageable
    
    private let beepQueue = DispatchQueue(label: "com.sktelecom.romaine.asr_beep_player")
    
    // MARK: AVAudioPlayer
    
    private lazy var startBeepPlayer = BeepType.start.makeAudioPlayer()
    private lazy var successBeepPlayer = BeepType.success.makeAudioPlayer()
    private lazy var failBeepPlayer = BeepType.fail.makeAudioPlayer()
    
    init(
        focusManager: FocusManageable,
        resourcesUrl: ASRBeepPlayerResourcesURL
    ) {
        self.focusManager = focusManager
        focusManager.add(channelDelegate: self)
        
        ASRBeepPlayer.resourcesUrl = resourcesUrl
    }
    
    // MARK: BeepType
    
    enum BeepType: String {
        case start
        case success
        case fail
    }
    
    // MARK: Internal (beep)
    
    func beep(type: BeepType) {
        guard type.isEnabled == true else { return }
        play(type: type)
        focusManager.requestFocus(channelDelegate: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            
            self.focusManager.releaseFocus(channelDelegate: self)
        }
    }
}

// MARK: - Private(AVAudioPlayer)

extension ASRBeepPlayer.BeepType {
    var isEnabled: Bool {
        switch self {
        case .start:
            return ASRBeepPlayer.isStartBeepEnabled
        case .success:
            return ASRBeepPlayer.isSuccessBeepEnabled
        case .fail:
            return ASRBeepPlayer.isFailBeepEnabled
        }
    }
    
    func makeAudioPlayer() -> AVAudioPlayer? {
        switch self {
        case .start:
            guard let startBeepResourceUrl = ASRBeepPlayer.resourcesUrl.startBeepResourceUrl else {
                return nil
            }
            return try? AVAudioPlayer(contentsOf: startBeepResourceUrl, fileTypeHint: AVFileType.wav.rawValue)
        case .success:
            guard let successBeepResourceUrl = ASRBeepPlayer.resourcesUrl.successBeepResourceUrl else {
                return nil
            }
            return try? AVAudioPlayer(contentsOf: successBeepResourceUrl, fileTypeHint: AVFileType.wav.rawValue)
        case .fail:
            guard let failBeepResourceUrl = ASRBeepPlayer.resourcesUrl.failBeepResourceUrl else {
                return nil
            }
            return try? AVAudioPlayer(contentsOf: failBeepResourceUrl, fileTypeHint: AVFileType.wav.rawValue)
        }
    }
}

// MARK: - Private (play / stop)

private extension ASRBeepPlayer {
    func play(type: BeepType) {
        beepQueue.async { [weak self] in
            let player: AVAudioPlayer?
            switch type {
            case .fail: player = self?.failBeepPlayer
            case .start: player = self?.startBeepPlayer
            case .success: player = self?.successBeepPlayer
            }
            
            if player?.isPlaying == false {
                player?.play()
            }
        }
    }
}

// MARK: - FocusChannelDelegate

extension ASRBeepPlayer: FocusChannelDelegate {
    public func focusChannelPriority() -> FocusChannelPriority {
        return .beep
    }
    
    public func focusChannelDidChange(focusState: FocusState) {
        log.debug(focusState)
    }
}
