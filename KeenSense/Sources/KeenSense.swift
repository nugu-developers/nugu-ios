//
//  KeenSense.swift
//  KeenSense
//
//  Created by DCs-OfficeMBP on 26/04/2019.
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
        prefix: "KeenSense")
    #else
    return NattyConfiguration(
        minLogLevel: .warning,
        maxDescriptionLevel: .warning,
        showPersona: true,
        prefix: "KeenSense")
    #endif
}

/// Turn the log enable and disable in `KeenSense`.
@available(*, deprecated, message: "Replace to `logLevel`")
public var logEnabled: Bool {
    get {
        switch log.configuration.minLogLevel {
        case .nothing:
            return false
        default:
            return true
        }
    }
    set {
        guard newValue == true else {
            log.configuration.minLogLevel = .nothing
            return
        }
        
        #if DEBUG
        log.configuration.minLogLevel = .debug
        #else
        log.configuration.minLogLevel = .warning
        #endif
    }
}

/// The minimum log level  in `KeenSense`.
public var logLevel: NattyLog.LogLevel {
    get {
        return log.configuration.minLogLevel
    }
    set {
        log.configuration.minLogLevel = newValue
    }
}

// MARK: - Stream Type

public enum StreamType: Int {
    case linearPcm16 = 0
    case linearPcm8
    case speex = 4
    case feature = 5
}

// MARK: - KeywordDetectorConst

enum KeywordDetectorConst {
    static let sampleRate = 16000
    static let channel = 1
}

// MARK: - Error

public enum KeywordDetectorError: Error {
    case initEngineFailed
    case initBufferFailed
    case unsupportedAudioFormat
    case noDataAvailable
    case alreadyActivated
}

// MARK: Keyword

public enum Keyword: Int, CustomStringConvertible, CaseIterable {
    case aria = 0 // ɑriɑ
    case tinkerbell = 3 // tɪŋkəbel
    
    public var description: String {
        switch self {
        case .aria:
            return "아리아"
        case .tinkerbell:
            return "팅커벨"
        }
    }
    
    var netFilePath: String {
        switch self {
        case .aria:
            return Bundle(for: TycheKeywordDetectorEngine.self).url(forResource: "skt_trigger_am_aria", withExtension: "raw")!.path
        case .tinkerbell:
            return Bundle(for: TycheKeywordDetectorEngine.self).url(forResource: "skt_trigger_am_tinkerbell", withExtension: "raw")!.path
        }
    }
    
    var searchFilePath: String {
        switch self {
        case .aria:
            return Bundle(for: TycheKeywordDetectorEngine.self).url(forResource: "skt_trigger_search_aria", withExtension: "raw")!.path
        case .tinkerbell:
            return Bundle(for: TycheKeywordDetectorEngine.self).url(forResource: "skt_trigger_search_tinkerbell", withExtension: "raw")!.path
        }
    }
}

