//
//  JadeMarble.swift
//  JadeMarble
//
//  Created by DCs-OfficeMBP on 16/05/2019.
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

import NattyLog

// MARK: - NattyLog

let log: Natty = Natty(by: nattyConfiguration)
private var nattyConfiguration: NattyConfiguration {
    #if DEBUG
    return NattyConfiguration(
        minLogLevel: .debug,
        maxDescriptionLevel: .error,
        showPersona: true,
        prefix: "JadeMarble")
    #else
    return NattyConfiguration(
        minLogLevel: .warning,
        maxDescriptionLevel: .warning,
        showPersona: true,
        prefix: "JadeMarble")
    #endif
}

/// The minimum log level  in `JadeMarble`.
public var logLevel: NattyLog.LogLevel {
    get {
        return log.configuration.minLogLevel
    }
    set {
        log.configuration.minLogLevel = newValue
    }
}

// MARK: - EndPointDetectorConst

public enum EndPointDetectorConst {
    static let inputStreamType: StreamType = .linearPcm16 // fixed by engine
    static let outputStreamType: StreamType = .speex // fixed by engine
}

// MARK: - Stream Type

public enum StreamType: Int {
    case linearPcm16 = 0
    case linearPcm8
    case speex = 4
    case feature = 5
}

// MARK: - EndPointDetectorError

public enum EndPointDetectorError: Error, LocalizedError {
    case initFailed
    case alreadyRunning
}

// MARK: - SpeexError

enum SpeexError: Error {
    case encodeFailed
}
