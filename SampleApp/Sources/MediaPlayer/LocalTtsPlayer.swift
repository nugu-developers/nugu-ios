//
//  LocalTtsPlayer.swift
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

// MARK: LocalTtsPlayerChannel - FocusChannelConfigurable

final class LocalTtsPlayerChannel: FocusChannelConfigurable {
    /// Refer to FocusChannelConfiguration's priority level
    /// FocusChannelConfiguration.recognition: 300
    /// FocusChannelConfiguration.information: 200
    /// FocusChannelConfiguration.content:       100
    var priority: Int {
        return 400
    }
}

// MARK: LocalTtsPlayer

final class LocalTtsPlayer: NSObject {
    static let shared = LocalTtsPlayer()
    
    override init() {
        super.init()
        
        NuguCentralManager.shared.client.focusManager.add(channelDelegate: self)
    }
    
    // MARK: TtsPlayer
    
    private var player: AVAudioPlayer?
    
    // MARK: FocusChannelConfigurable
    
    private var channel = LocalTtsPlayerChannel()
    
    enum TtsType {
        case deviceGatewayNetworkError
        case deviceGatewayAuthServerError
        case deviceGatewayAuthError
        case deviceGatewayTimeout
        case deviceGatewayRequestUnacceptable
        case deviceGatewayTtsConnectionError
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
            case .deviceGatewayTtsConnectionError,
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
    
// MARK: FocusChannelDelegate

extension LocalTtsPlayer: FocusChannelDelegate {
    func focusChannelConfiguration() -> FocusChannelConfigurable {
        return channel
    }
    
    func focusChannelDidChange(focusState: FocusState) {
        log.debug("focusChannelDidChange = \(focusState)")
    }
}

// MARK: AVAudioPlayerDelegate

extension LocalTtsPlayer: AVAudioPlayerDelegate {
    /* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        NuguCentralManager.shared.client.focusManager.releaseFocus(channelDelegate: self)
    }
    
    /* if an error occurs while decoding it will be reported to the delegate. */
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        NuguCentralManager.shared.client.focusManager.releaseFocus(channelDelegate: self)
    }
}

// MARK: Internal (play)
    
extension LocalTtsPlayer {
    func playLocalTts(type: TtsType) {
        guard let url = Bundle.main.url(forResource: type.fileName, withExtension: type.extention) else {
            log.error("Can't find sound file")
            return
        }
        
        do {
            NuguCentralManager.shared.client.focusManager.requestFocus(channelDelegate: self)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: type.fileTypeHint)
            player?.delegate = self
            player?.play()
        } catch {
            log.error("Failed to play local tts file : \(error.localizedDescription)")
            NuguCentralManager.shared.client.focusManager.releaseFocus(channelDelegate: self)
        }
    }
}
