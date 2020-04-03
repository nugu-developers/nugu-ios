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

public struct ASROptions: Equatable {
    /// Max duration from speech start to end.
    public let maxDuration: Int
    /// Max duration of waiting for speech.
    public let timeout: Int
    /// The engine waits this time then consider speech end.
    public let pauseLength: Int
    public let sampleRate = 16000.0
    public let initiator: Initiator
    public let encoding: Encoding
    public let endPointing: EndPointing
    
    /// - Parameters:
    ///   - maxDuration: Max duration from speech start to end.
    ///   - timeout: Max duration of waiting for speech.
    ///   - pauseLength: The engine waits this time then consider speech end.
    public init(
        maxDuration: Int = 10,
        timeout: Int = 7,
        pauseLength: Int = 700,
        initiator: Initiator = .user,
        encoding: Encoding = .partial,
        endPointing: EndPointing = .client
    ) {
        self.maxDuration = maxDuration
        self.timeout = timeout
        self.pauseLength = pauseLength
        self.initiator = initiator
        self.encoding = encoding
        self.endPointing = endPointing
    }

    public enum Initiator: Equatable {
        case wakeUpKeyword(data: Data, padding: Int)
        case user
        case scenario
    }

    public enum Encoding: String {
        case partial = "PARTIAL"
        case complete = "COMPLETE"
    }
    
    public enum EndPointing: String {
        case client = "CLIENT"
        case server = "SERVER"
    }
}
