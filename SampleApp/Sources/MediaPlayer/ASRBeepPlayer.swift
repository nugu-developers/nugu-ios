//
//  ASRBeepPlayer.swift
//  SampleApp
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
    private let beepQueue = DispatchQueue(label: "com.sktelecom.romaine.asr_beep_player")
    
    // MARK: ASRBeepPlayer
    
    private lazy var startBeepPlayer = BeepType.start.makeAudioPlayer()
    private lazy var successBeepPlayer = BeepType.success.makeAudioPlayer()
    private lazy var failBeepPlayer = BeepType.fail.makeAudioPlayer()
    
    private let focusManager: FocusManageable
    
    init(focusManager: FocusManageable) {
        self.focusManager = focusManager
        
        focusManager.add(channelDelegate: self)
    }
    
    // MARK: BeepType
    
    enum BeepType: String {
        case start
        case success
        case fail
    }
    
    // MARK: Internal (beep)
    
    func beep(type: BeepType) {
        play(type: type)
        focusManager.requestFocus(channelDelegate: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            
            self.focusManager.releaseFocus(channelDelegate: self)
        }
    }
}

// MARK: - Private(AVAudioPlayer)

private extension ASRBeepPlayer.BeepType {
    var isEnabled: Bool {
        switch self {
        case .start: return UserDefaults.Standard.useAsrStartSound
        case .success: return UserDefaults.Standard.useAsrSuccessSound
        case .fail: return UserDefaults.Standard.useAsrFailSound
        }
    }
    
    var fileName: String {
        switch self {
        case .start:
            return "listening_start"
        case .success:
            return "listening_end"
        case .fail:
            return "responsefail"
        }
    }
        
    var extention: String {
        return "wav"
    }
    
    var fileTypeHint: String {
        return AVFileType.wav.rawValue
    }
    
    func makeAudioPlayer() -> AVAudioPlayer? {
        guard let failBeepUrl = Bundle.main.url(forResource: fileName, withExtension: extention) else { return nil }
        return try? AVAudioPlayer(contentsOf: failBeepUrl, fileTypeHint: fileTypeHint)
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
    func focusChannelPriority() -> FocusChannelPriority {
        return .beep
    }
    
    func focusChannelDidChange(focusState: FocusState) {
        log.debug(focusState)
    }
}
