//
//  DataStreamPlayerError.swift
//  SilverTray
//
//  Created by childc on 16/08/2019.
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

public enum DataStreamPlayerError: Error {
    case unsupportedAudioFormat
    case decodeFailed
    case seekRangeExceed
    case audioBufferClosed
    case unavailableSource
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedAudioFormat:
            return "Your device does not support audio format you set"
        case .decodeFailed:
            return "Received data cannot be decoded"
        case .seekRangeExceed:
            return "seek position is weired"
        case .audioBufferClosed:
            return "No data can be appended any longer. because last data is setted."
        case .unavailableSource:
            return "Cannot download from url"
        }
    }
}
