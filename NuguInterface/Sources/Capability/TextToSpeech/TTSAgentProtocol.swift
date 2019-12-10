//
//  TTSAgentProtocol.swift
//  NuguInterface
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

/// The `TTSAgent` handles directives for controlling speech playback.
public protocol TTSAgentProtocol:
CapabilityAgentable,
ContextInfoDelegate,
FocusChannelDelegate,
HandleDirectiveDelegate,
PlaySyncDelegate,
SpeakerVolumeDelegate {
    /// <#Description#>
    /// - Parameter focusManager: <#focusManager description#>
    /// - Parameter channel: <#channel description#>
    /// - Parameter mediaPlayerFactory: <#mediaPlayerFactory description#>
    /// - Parameter upstreamDataSender: <#upstreamDataSender description#>
    /// - Parameter playSyncManager: <#playSyncManager description#>
    init(
        focusManager: FocusManageable,
        channel: FocusChannelConfigurable,
        mediaPlayerFactory: MediaPlayableFactory,
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable
    )
    
    /// Adds a delegate to be notified of `TTSState` changes.
    ///
    /// - Parameter delegate: The object to add.
    func add(delegate: TTSAgentDelegate)
    
    /// Removes a delegate from `TTSAgent`.
    ///
    /// - Parameter delegate: The object to remove.
    func remove(delegate: TTSAgentDelegate)
    
    /// Request voice synthesis and playback.
    ///
    /// - Parameter text: The obejct to request speech synthesis.
    /// - Parameter playServiceId: The unique identifier to specify play service.
    func requestTTS(text: String, playServiceId: String?, handler: ((TTSResult) -> Void)?)
    
    /// Stops playback
    func stopTTS(cancelAssociated: Bool)
}

// MARK: - Optional

public extension TTSAgentProtocol {
    /// Request voice synthesis and playback.
    ///
    /// - Parameter text: The obejct to request speech synthesis.
    func requestTTS(text: String) {
        requestTTS(text: text, playServiceId: nil, handler: nil)
    }
    
    /// Stops playback
    func stopTTS() {
        stopTTS(cancelAssociated: true)
    }
}
