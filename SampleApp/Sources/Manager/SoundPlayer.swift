//
//  SoundPlayer.swift
//  SampleApp-iOS
//
//  Created by jin kim on 24/06/2019.
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

struct SoundPlayer {
    
    // MARK: SoundPlayer
    
    private static var player: AVAudioPlayer?
    
    // MARK: SoundType
    
    enum SoundType {
        case asrBeep(type: BeepType)
        case localTts(type: TtsType)
        
        enum BeepType: String {
            case start
            case success
            case fail
        }
        
        enum TtsType: Int {
            case deviceGatewayNetworkError = 1
            case deviceGatewayAuthServerError
            case deviceGatewayAuthError
            case deviceGatewayTimeout
            case deviceGatewayRequestUnacceptable
            case deviceGatewayTtsConnectionError
            case deviceGatewayPlayRouterConnectionError
            case playRouterFallbackServerConnectionError
            case pocStateServiceTerminated
        }
        
        fileprivate var isEnabled: Bool {
            switch self {
            case .asrBeep(let type):
                switch type {
                case .start: return UserDefaults.Standard.useAsrStartSound
                case .success: return UserDefaults.Standard.useAsrSuccessSound
                case .fail: return UserDefaults.Standard.useAsrFailSound
                }
            case .localTts:
                return true
            }
        }
        
        fileprivate var fileName: String {
            switch self {
            case .asrBeep(let type):
                return "asr\(type.rawValue.capitalized)"
            case .localTts(let type):
                switch type {
                case .deviceGatewayNetworkError,
                     .deviceGatewayAuthServerError,
                     .deviceGatewayAuthError,
                     .deviceGatewayTimeout,
                     .deviceGatewayRequestUnacceptable:
                    return "device_GW_error_00\(String(type.rawValue))"
                case .deviceGatewayTtsConnectionError,
                     .deviceGatewayPlayRouterConnectionError,
                     .playRouterFallbackServerConnectionError:
                    return "device_GW_error_006"
                case .pocStateServiceTerminated:
                    return "poc_end_error"
                }
            }
        }
        
        fileprivate var extention: String {
            return "wav"
        }
        
        fileprivate var fileTypeHint: String {
            return AVFileType.wav.rawValue
        }
    }
    
    static func playSound(soundType: SoundType) {
        guard let url = Bundle.main.url(forResource: soundType.fileName, withExtension: soundType.extention) else {
            log.error("Can't find sound file")
            return
        }
        
        guard soundType.isEnabled == true else {
            log.info("\(soundType) is disabled")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: soundType.fileTypeHint)
            player?.play()
        } catch {
            log.error("Can't find sound file")
            log.error("Failed to play sound file : \(error.localizedDescription)")
        }
    }
}
