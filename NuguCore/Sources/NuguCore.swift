//
//  NuguCore.swift
//  NuguCore
//
//  Created by yonghoonKwon on 2019/12/12.
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
        prefix: "NuguCore")
    #else
    return NattyConfiguration(
        minLogLevel: .warning,
        maxDescriptionLevel: .warning,
        showPersona: true,
        prefix: "NuguCore")
    #endif
}

/// The minimum log level  in `NuguCore`.
public var logLevel: NattyLog.LogLevel {
    get {
        return log.configuration.minLogLevel
    }
    set {
        log.configuration.minLogLevel = newValue
    }
}

#if DEPLOY_OTHER_PACKAGE_MANAGER
public let nuguSDKVersion = (Bundle(for: AuthorizationStore.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0")
#else
// FIXME: 현재는 SPM에서 버전을 가져올 방법이 없다.
public let nuguSDKVersion = "1.7.8"
#endif
