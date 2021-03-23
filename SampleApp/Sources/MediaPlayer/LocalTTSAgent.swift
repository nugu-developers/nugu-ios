//
//  LocalTTSAgent.swift
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

// MARK: LocalTTSPlayer

final class LocalTTSAgent: NSObject {
    private let focusManager: FocusManageable
    
    init(focusManager: FocusManageable) {
        self.focusManager = focusManager
        super.init()
        
        focusManager.add(channelDelegate: self)
    }
    
    // MARK: TTSPlayer
    
    private var player: AVAudioPlayer?
    
    // MARK: FocusChannelPriority
    
    private let channelPriority = FocusChannelPriority(requestPriority: 400, maintainPriority: 100)
    
    // MARK: CurrentTTSType
    
    private var requestedTTSType: TTSType?
    
    private var playCompletion: (() -> Void)?
    
    enum TTSType {
        case deviceGatewayNetworkError
        case deviceGatewayAuthServerError
        case deviceGatewayAuthError
        case deviceGatewayTimeout
        case deviceGatewayRequestUnacceptable
        case deviceGatewayTTSConnectionError
        case deviceGatewayPlayRouterConnectionError
        case playRouterFallbackServerConnectionError
        
        fileprivate var fileName: String {
            switch self {
            case .deviceGatewayNetworkError:
                return "device_GW_error_001"
            case .deviceGatewayAuthServerError:
                return "device_GW_error_002"
            case .deviceGatewayAuthError:
                return "device_GW_error_003"
            case .deviceGatewayTimeout:
                return "device_GW_error_004"
            case .deviceGatewayRequestUnacceptable:
                return "device_GW_error_005"
            case .deviceGatewayTTSConnectionError,
                 .deviceGatewayPlayRouterConnectionError,
                 .playRouterFallbackServerConnectionError:
                return "device_GW_error_006"
            }
        }
        
        fileprivate var extention: String {
            return "wav"
        }
        
        fileprivate var fileTypeHint: String {
            return AVFileType.wav.rawValue
        }
    }
}

// MARK: Internal (play)
    
extension LocalTTSAgent {
    func playLocalTTS(type: TTSType, completion: (() -> Void)? = nil) {
        requestedTTSType = type
        focusManager.requestFocus(channelDelegate: self)
        playCompletion = completion
    }
    
    func stopLocalTTS() {
        if requestedTTSType != nil {
            focusManager.releaseFocus(channelDelegate: self)
        }
    }
}

// MARK: Private

private extension LocalTTSAgent {
    func play(type: TTSType) {
        // when ttsPlayer has been paused, just resuming the player is enough
        if player != nil && player?.isPlaying == false {
            player?.play()
            return
        }
        guard let url = Bundle.main.url(forResource: type.fileName, withExtension: type.extention) else {
            log.error("Can't find sound file")
            focusManager.releaseFocus(channelDelegate: self)
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: type.fileTypeHint)
            player?.delegate = self
            player?.play()
        } catch {
            log.error("Failed to play local tts file : \(error.localizedDescription)")
            focusManager.releaseFocus(channelDelegate: self)
        }
    }
    
    func stop() {
        player?.stop()
        player = nil
        requestedTTSType = nil
        playCompletion?()
        playCompletion = nil
    }
}

// MARK: FocusChannelDelegate

extension LocalTTSAgent: FocusChannelDelegate {
    func focusChannelPriority() -> FocusChannelPriority {
        return channelPriority
    }
    
    func focusChannelDidChange(focusState: FocusState) {
        log.debug("focusChannelDidChange = \(focusState)")
        guard let requestedTTSType = requestedTTSType else {
            log.error("focus channel has been changed while requested tts is nil")
            return
        }
        switch focusState {
        case .foreground:
            play(type: requestedTTSType)
        case .background:
            player?.pause()
        case .nothing:
            stop()
        // Ignore prepare
        default:
            break
        }
    }
}

// MARK: AVAudioPlayerDelegate

extension LocalTTSAgent: AVAudioPlayerDelegate {
    /* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        focusManager.releaseFocus(channelDelegate: self)
    }
    
    /* if an error occurs while decoding it will be reported to the delegate. */
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        focusManager.releaseFocus(channelDelegate: self)
    }
}
