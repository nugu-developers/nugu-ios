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

let log = KeenSenseConfiguration.natty

// MARK: - KeenSenseConfiguration

public enum KeenSenseConfiguration {
    fileprivate static let natty: NattyLog.Natty = NattyLog.Natty(by: nattyConfiguration)
    private static var nattyConfiguration: NattyLog.NattyConfiguration {
        #if DEBUG
        return NattyLog.NattyConfiguration(
            minLogLevel: .debug,
            maxDescriptionLevel: .error,
            showPersona: true,
            prefix: "KeenSense")
        #else
        return NattyLog.NattyConfiguration(
            minLogLevel: .warning,
            maxDescriptionLevel: .warning,
            showPersona: true,
            prefix: "KeenSense")
        #endif
    }
    
    public static var logEnabled: Bool {
        set {
            switch newValue {
            case true:
                #if DEBUG
                natty.configuration.minLogLevel = .debug
                #else
                natty.configuration.minLogLevel = .warning
                #endif
            case false:
                natty.configuration.minLogLevel = .nothing
            }
        } get {
            switch nattyConfiguration.minLogLevel {
            case .nothing:
                return false
            default:
                return true
            }
        }
    }
}

// MARK: - KeyWordDetector

public enum KeyWord: Int, CustomStringConvertible, CaseIterable {
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
}

/// <#Description#>
public enum KeyWordDetectorState {
    /// <#Description#>
    case active
    /// <#Description#>
    case inactive
}

// MARK: - Stream Type

public enum StreamType: Int {
    case linearPcm16 = 0
    case linearPcm8
    case speex = 4
    case feature = 5
}

// MARK: - KeywordDetectorConst

enum KeyWordDetectorConst {
    static let sampleRate = 16000
    static let channel = 1
}

// MARK: - Error

public enum KeyWordDetectorError: Error {
    case initEngineFailed
    case initBufferFailed
    case unsupportedAudioFormat
    case noDataAvailable
    case alreadyActivated
}

public enum SpeexError: Error {
    case encodeFailed
}
