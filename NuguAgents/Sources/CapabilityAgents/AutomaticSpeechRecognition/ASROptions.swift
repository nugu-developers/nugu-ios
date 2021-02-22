//
//  ASROptions.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/04/02.
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

/// <#Description#>
public struct ASROptions {
    /// Max duration from speech start to end.
    public let maxDuration: TimeIntervallic
    /// Max duration of waiting for speech.
    public let timeout: TimeIntervallic
    /// The engine waits this time then consider speech end.
    public let pauseLength: TimeIntervallic
    /// <#Description#>
    public let sampleRate = 16000.0
    /// <#Description#>
    public let encoding: Encoding
    /// <#Description#>
    public let endPointing: EndPointing
    
    /// - Parameters:
    ///   - maxDuration: Max duration from speech start to end.
    ///   - timeout: Max duration of waiting for speech.
    ///   - pauseLength: The engine waits this time then consider speech end.
    public init(
        maxDuration: TimeIntervallic = NuguTimeInterval(seconds: 10),
        timeout: TimeIntervallic = NuguTimeInterval(seconds: 7),
        pauseLength: TimeIntervallic = NuguTimeInterval(milliseconds: 700),
        encoding: Encoding = .partial,
        endPointing: EndPointing
    ) {
        self.maxDuration = maxDuration
        self.timeout = timeout
        self.pauseLength = pauseLength
        self.encoding = encoding
        self.endPointing = endPointing
    }
    
    /// <#Description#>
    public enum Encoding {
        case partial
        case complete
    }
    
    /// <#Description#>
    public enum EndPointing: Equatable {
        case client
        /// Server side end point detector does not support yet.
        case server
    }
}

// MARK: - ASROptions.EndPointing + server value

extension ASROptions.Encoding {
    var value: String {
        switch self {
        case .partial: return "PARTIAL"
        case .complete: return "COMPLETE"
        }
    }
}

// MARK: - ASROptions.EndPointing + server value

extension ASROptions.EndPointing {
    var value: String {
        switch self {
        case .client: return "CLIENT"
        case .server: return "SERVER"
        }
    }
}
