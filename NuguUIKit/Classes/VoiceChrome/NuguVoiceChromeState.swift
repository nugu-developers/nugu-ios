//
//  NuguVoiceChromeState.swift
//  NuguUIKit
//
//  Created by jin kim on 2019/10/23.
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

public enum NuguVoiceChromeState {
    case listeningPassive
    case listeningActive
    case processing
    case speaking
    case speakingError
}

extension NuguVoiceChromeState {
    var animationFileName: String {
        get {
            switch self {
            case .listeningPassive:
                return "LP"
            case .listeningActive:
                return "LA"
            case .processing:
                return "PC_02"
            case .speaking:
                return "SP_02"
            case .speakingError:
                return "ESP_02"
            }
        }
    }
}

