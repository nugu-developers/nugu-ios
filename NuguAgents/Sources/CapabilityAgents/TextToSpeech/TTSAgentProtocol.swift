//
//  TTSAgentProtocol.swift
//  NuguAgents
//
//  Created by MinChul Lee on 05/05/2019.
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

import NuguCore
import NuguUtils

/// The `TTSAgent` handles directives for controlling speech playback.
public protocol TTSAgentProtocol: CapabilityAgentable, TypedNotifyable {
    /// Returns the current time of the current player item.
    ///
    /// This function retrieves the offset(seconds) of the current `MediaPlayable` handled by the `TTSAgent`.
    var offset: Int? { get }
    
    /// The duration of the current player item.
    ///
    /// This function retrieves the duration(seconds) of the current `MediaPlayable` handled by the `TTSAgent`.
    var duration: Int? { get }
    
    /// The audio playback volume for the player.
    ///
    /// This function retrieves the volume of the current `MediaPlayable` handled by the `TTSAgent`.
    var volume: Float { get set }
    
    /// The audio playback speed for the player
    ///
    /// This function retrieves the speed of the current `OpusPlayer`
    var speed: Float { get set }
    
    /// The cancellation policy when playback is implicitly stopped.
    var directiveCancelPolicy: DirectiveCancelPolicy { get set }
    
    /// Request voice synthesis and playback.
    ///
    /// - Parameter text: The obejct to request speech synthesis.
    /// - Parameter playServiceId: The unique identifier to specify play service.
    /// - Parameter handler: <#handler description#>
    /// - Returns: The dialogRequestId for request.
    @discardableResult func requestTTS(
        text: String,
        playServiceId: String?,
        handler: ((_ ttsResult: TTSResult, _ dialogRequestId: String) -> Void)?
    ) -> String
    
    /// Stops playback
    /// - Parameter cancelAssociation: true: cancel all associated directives, false : only stop tts
    func stopTTS(cancelAssociation: Bool)
}

// MARK: - Default

public extension TTSAgentProtocol {
    @discardableResult func requestTTS(text: String) -> String {
        return requestTTS(text: text, playServiceId: nil, handler: nil)
    }
    
    @discardableResult func requestTTS(text: String, playServiceId: String?) -> String {
        return requestTTS(text: text, playServiceId: playServiceId, handler: nil)
    }
    
    @discardableResult func requestTTS(text: String, handler: ((_ ttsResult: TTSResult, _ dialogRequestId: String) -> Void)? = nil) -> String {
        return requestTTS(text: text, playServiceId: nil, handler: handler)
    }
    
    /// Stops playback
    func stopTTS() {
        stopTTS(cancelAssociation: true)
    }
}
