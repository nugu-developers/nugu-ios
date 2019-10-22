//
//  CrashReport.swift
//  NuguInterface
//
//  Created by jin kim on 27/05/2019.
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

/// <#Description#>
public struct CrashReport: Encodable {
    /// <#Description#>
    public let reportLevel: CrashReport.ReportLevel
    /// <#Description#>
    public let message: String
    /// <#Description#>
    public let detail: String
    
    /// <#Description#>
    /// - Parameter level: <#level description#>
    /// - Parameter message: <#message description#>
    /// - Parameter detail: <#detail description#>
    public init(level: CrashReport.ReportLevel, message: String, detail: String) {
        self.reportLevel = level
        self.message = message
        self.detail = detail
    }
    
    /// <#Description#>
    public enum ReportLevel: Int {
        /// <#Description#>
        case error = 0
        /// <#Description#>
        case warn = 1
        /// <#Description#>
        case info = 2
        /// <#Description#>
        case debug = 3
        /// <#Description#>
        case trace = 4
    }
    
    private enum CodingKeys: String, CodingKey {
        case level
        case message
        case detail
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reportLevel.rawValue, forKey: .level)
        try container.encode(message, forKey: .message)
        try container.encode(detail, forKey: .detail)
    }
}
