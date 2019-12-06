//
//  SpeakerAgentProtocol.swift
//  NuguInterface
//
//  Created by yonghoonKwon on 23/05/2019.
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

/// <#Description#>
public protocol SpeakerAgentProtocol:
CapabilityAgentable,
ContextInfoDelegate,
HandleDirectiveDelegate {
    /// <#Description#>
    /// - Parameter messageSender: <#messageSender description#>
    init(messageSender: MessageSendable)
    
    /// <#Description#>
    var delegate: SpeakerAgentDelegate? { get set }
    
    /// <#Description#>
    /// - Parameter speakerVolumeDelegate: <#handleDirectiveDelegate description#>
    func add(speakerVolumeDelegate: SpeakerVolumeDelegate)
    /// <#Description#>
    /// - Parameter speakerVolumeDelegate: <#handleDirectiveDelegate description#>
    func remove(speakerVolumeDelegate: SpeakerVolumeDelegate)
    
    func set(type: SpeakerVolumeType, muted: Bool)
}
