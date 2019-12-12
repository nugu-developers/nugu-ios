//
//  AppFocusChannelConfiguration.swift
//  SampleApp
//
//  Created by jin kim on 2019/12/11.
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

import NuguInterface

enum AppFocusChannelConfiguration: FocusChannelConfigurable {
    case localTTS
    
    /// Refer to FocusChannelConfiguration's priority level
    /// FocusChannelConfiguration.recognition: 300
    /// FocusChannelConfiguration.information: 200
    /// FocusChannelConfiguration.content:       100
    var priority: Int {
        switch self {
        case .localTTS:
            return 400
        }
    }
}
