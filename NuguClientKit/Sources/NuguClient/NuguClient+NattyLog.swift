//
//  NuguClient+NattyLog.swift
//  NuguClientKit
//
//  Created by yonghoonKwon on 2019/12/11.
//  Copyright © 2019 SK Telecom Co., Ltd. All rights reserved.
//

import Foundation

import NattyLog

let log = NuguClient.natty

extension NuguClient {
    fileprivate static let natty: NattyLog.Natty = NattyLog.Natty(by: nattyConfiguration)
    private static var nattyConfiguration: NattyLog.NattyConfiguration {
        #if DEBUG
        return NattyLog.NattyConfiguration(
            minLogLevel: .debug,
            maxDescriptionLevel: .error,
            showPersona: true,
            prefix: "NuguClient")
        #else
        return NattyLog.NattyConfiguration(
            minLogLevel: .warning,
            maxDescriptionLevel: .warning,
            showPersona: true,
            prefix: "NuguClient")
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
}
