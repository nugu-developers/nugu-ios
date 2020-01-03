//
//  LocalTTSPlayer.swift
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

import NuguInterface

// MARK: LocalTTSPlayer

final class LocalTTSPlayer: NSObject {
    static let shared = LocalTTSPlayer()
    
    override init() {
        super.init()
        
        NuguCentralManager.shared.client.focusManager.add(channelDelegate: self)
    }
    
    // MARK: TTSPlayer
    
    private var player: AVAudioPlayer?
    
    // MARK: FocusChannelPriority
    
    private let channelPriority = FocusChannelPriority(rawValue: 400)
    
    // MARK: CurrentTTSType
    
    private var requestedTTSType: TTSType?
    
    enum TTSType {
        case deviceGatewayNetworkError
        case deviceGatewayAuthServerError
        case deviceGatewayAuthError
        case deviceGatewayTimeout
        case deviceGatewayRequestUnacceptable
        case deviceGatewayTTSConnectionError
        case deviceGatewayPlayRouterConnectionError
        case playRouterFallbackServerConnectionError
        case pocStateServiceTerminated
        
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
            case .pocStateServiceTerminated:
                return "poc_end_error"
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
    
extension LocalTTSPlayer {
    func playLocalTTS(type: TTSType) {
        requestedTTSType = type
        NuguCentralManager.shared.client.focusManager.requestFocus(channelDelegate: self)
    }
}

// MARK: Private

private extension LocalTTSPlayer {
    func play(type: TTSType) {
        // when ttsPlayer has been paused, just resuming the player is enough
        if player != nil && player?.isPlaying == false {
            player?.play()
            return
        }
        guard let url = Bundle.main.url(forResource: type.fileName, withExtension: type.extention) else {
            log.error("Can't find sound file")
            NuguCentralManager.shared.client.focusManager.releaseFocus(channelDelegate: self)
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: type.fileTypeHint)
            player?.delegate = self
            player?.play()
        } catch {
            log.error("Failed to play local tts file : \(error.localizedDescription)")
            NuguCentralManager.shared.client.focusManager.releaseFocus(channelDelegate: self)
        }
    }
    
    func stop() {
        player?.stop()
        player = nil
        requestedTTSType = nil
    }
}

// MARK: FocusChannelDelegate

extension LocalTTSPlayer: FocusChannelDelegate {
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
        }
    }
}

// MARK: AVAudioPlayerDelegate

extension LocalTTSPlayer: AVAudioPlayerDelegate {
    /* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        NuguCentralManager.shared.client.focusManager.releaseFocus(channelDelegate: self)
    }
    
    /* if an error occurs while decoding it will be reported to the delegate. */
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        NuguCentralManager.shared.client.focusManager.releaseFocus(channelDelegate: self)
    }
}
