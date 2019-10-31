//
//  NuguCoreApp.swift
//  NuguCore
//
//  Created by MinChul Lee on 09/04/2019.
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

let log = NuguApp.natty

/// <#Description#>
public class NuguApp {
    // Static
    fileprivate static let natty: Natty = Natty(by: nattyConfiguration)
    private static var nattyConfiguration: NattyLog.NattyConfiguration {
        #if DEBUG
        return NattyLog.NattyConfiguration(
            minLogLevel: .debug,
            maxDescriptionLevel: .error,
            showPersona: true,
            prefix: "Nugu")
        #else
        return NattyLog.NattyConfiguration(
            minLogLevel: .warning,
            maxDescriptionLevel: .warning,
            showPersona: true,
            prefix: "Nugu")
        #endif
    }
    
    /// <#Description#>
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
    
    /// <#Description#>
    public static let shared = NuguApp()
    
    /// <#Description#>
    public let configuration: NuguConfiguration

    // singleton
    private init() {
        guard let url = Bundle.main.url(forResource: "Nugu-Info", withExtension: "plist") else {
            configuration = NuguConfiguration()
            log.warning("Nugu-Info.plist is not exist")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            configuration = try PropertyListDecoder().decode(NuguConfiguration.self, from: data)
        } catch {
            configuration = NuguConfiguration()
            log.error("Nugu-Info.plist is not valid")
        }
    }
}
