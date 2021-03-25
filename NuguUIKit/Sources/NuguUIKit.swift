//
//  NuguUIKit.swift
//  NuguUIKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/11/28.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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

let log: Natty = NattyLog.Natty(by: nattyConfiguration)

private var nattyConfiguration: NattyConfiguration {
    #if DEBUG
    return NattyConfiguration(
        minLogLevel: .debug,
        maxDescriptionLevel: .error,
        showPersona: true,
        prefix: "NuguUIKit")
    #else
    return NattyConfiguration(
        minLogLevel: .warning,
        maxDescriptionLevel: .warning,
        showPersona: true,
        prefix: "NuguUIKit")
    #endif
}

/// The minimum log level  in `NuguUIKit`.
public var logLevel: NattyLog.LogLevel {
    get {
        return log.configuration.minLogLevel
    }
    set {
        log.configuration.minLogLevel = newValue
    }
}
