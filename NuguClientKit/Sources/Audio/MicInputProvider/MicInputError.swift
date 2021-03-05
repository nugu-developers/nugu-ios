//
//  MicInputError.swift
//  NuguCore
//
//  Created by MinChul Lee on 2020/05/06.
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
public enum MicInputError: Error {
    case audioFormatError
    case audioHardwareError
    case resamplerError(source: AVAudioFormat, dest: AVAudioFormat)
}

// MARK: - LocalizedError

extension MicInputError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .audioFormatError:
            return "audio format error"
        case .audioHardwareError:
            return "audio hardware is not available"
        case .resamplerError(let source, let dest):
            return "cannot resample. source(\(source)) or destnation (\(dest)) sample may be wrong"
        }
    }
}
