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

// MARK: Keyword

public enum Keyword: CustomStringConvertible, CaseIterable {
    public static var allCases: [Keyword] = [
        .aria, .tinkerbell // TODO: - Adds custom wakeup word
    ]
    
    case aria // ɑriɑ
    case tinkerbell // tɪŋkəbel
    case custom(description: String, netFilePath: String, searchFilePath: String)
    
    public init?(
        rawValue: Int,
        description: String? = nil,
        netFilePath: String? = nil,
        searchFilePath: String? = nil
    ) {
        switch rawValue {
        case Self.aria.rawValue:
            self = .aria
        case Self.tinkerbell.rawValue:
            self = .tinkerbell
        case -1:
            self = .custom(
            description: description ?? "",
            netFilePath: netFilePath ?? "",
            searchFilePath: searchFilePath ?? ""
        )
        default:
            return nil
        }
    }
    
    public var rawValue: Int {
        switch self {
        case .aria: return 0
        case .tinkerbell: return 3
        case .custom: return -1
        }
    }
    
    public var description: String {
        switch self {
        case .aria:
            return "아리아"
        case .tinkerbell:
            return "팅커벨"
        case .custom(let description, _, _):
            return description
        }
    }
    
    var netFilePath: String {
        #if DEPLOY_OTHER_PACKAGE_MANAGER
        switch self {
        case .aria:
            return Bundle(for: TycheKeywordDetectorEngine.self).url(forResource: "skt_trigger_am_aria", withExtension: "raw")!.path
        case .tinkerbell:
            return Bundle(for: TycheKeywordDetectorEngine.self).url(forResource: "skt_trigger_am_tinkerbell", withExtension: "raw")!.path
        case .custom(_, let netFilePath, _):
            return netFilePath
        }
        #else
        switch self {
        case .aria:
            return Bundle.module.url(forResource: "skt_trigger_am_aria", withExtension: "raw")!.path
        case .tinkerbell:
            return Bundle.module.url(forResource: "skt_trigger_am_tinkerbell", withExtension: "raw")!.path
        case .custom(_, let netFilePath, _):
            return netFilePath
        }
        #endif
    }
    
    var searchFilePath: String {
        #if DEPLOY_OTHER_PACKAGE_MANAGER
        switch self {
        case .aria:
            return Bundle(for: TycheKeywordDetectorEngine.self).url(forResource: "skt_trigger_search_aria", withExtension: "raw")!.path
        case .tinkerbell:
            return Bundle(for: TycheKeywordDetectorEngine.self).url(forResource: "skt_trigger_search_tinkerbell", withExtension: "raw")!.path
        case .custom(_, _, let searchFilePath):
            return searchFilePath
        }
        #else
        switch self {
        case .aria:
            return Bundle.module.url(forResource: "skt_trigger_search_aria", withExtension: "raw")!.path
        case .tinkerbell:
            return Bundle.module.url(forResource: "skt_trigger_search_tinkerbell", withExtension: "raw")!.path
        case .custom(_, _, let searchFilePath):
            return searchFilePath
        }
        #endif
    }
}
