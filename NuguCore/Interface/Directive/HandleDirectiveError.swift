//
//  HandleDirectiveError.swift
//  NuguCore
//
//  Created by yonghoonKwon on 23/05/2019.
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
public enum HandleDirectiveError: Error {
    /// <#Description#>
    case notImplemented
    /// <#Description#>
    /// - Parameter type: <#type description#>
    case notSupported(type: String)
    /// <#Description#>
    /// - Parameter type: <#type description#>
    case handlerNotFound(type: String)
    /// <#Description#>
    /// - Parameter message: <#message description#>
    case handleDirectiveError(message: String)
}

// MARK: - LocalizedError

extension HandleDirectiveError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Handler not implemented"
        case .notSupported(let type):
            return "Handler does not support \(type)"
        case .handlerNotFound(let type):
            return "Handler not found \(type)"
        case .handleDirectiveError(let message):
            return "Handle directive error \(message)"
        }
    }
}
