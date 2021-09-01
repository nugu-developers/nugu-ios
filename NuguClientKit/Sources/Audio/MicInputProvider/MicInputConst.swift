//
//  MicInputConst.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 07/05/2019.
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
import AVFoundation

/// <#Description#>
enum MicInputConst {
    /// <#Description#>
    public static let defaultChannelCount: AVAudioChannelCount = AVAudioChannelCount(AVAudioSession.sharedInstance().inputNumberOfChannels) == 0 ? 1 : AVAudioChannelCount(AVAudioSession.sharedInstance().inputNumberOfChannels) // Some devices returns 0 in special situations
    /// <#Description#>
    public static let defaultSampleRate: Double = 16000.0
    /// <#Description#>
    public static let defaultBus = 0
    /// <#Description#>
    public static let defaultFormat: AVAudioCommonFormat = .pcmFormatInt16
    /// <#Description#>
    public static let defaultInterLeavingSetting = false
}
