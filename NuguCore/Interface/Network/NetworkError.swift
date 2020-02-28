//
//  NetworkError.swift
//  NuguCore
//
//  Created by MinChul Lee on 01/05/2019.
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
public enum NetworkError: Error {
    /// <#Description#>
    case noSuitableResourceServer
    /// <#Description#>
    case invalidParameter
    /// <#Description#>
    case badRequest
    /// <#Description#>
    case authError
    /// <#Description#>
    case streamInitializeFailed
    /// <#Description#>
    case nilResponse
    /// <#Description#>
    case timeout
    /// <#Description#>
    case invalidMessageReceived
    /// <#Description#>
    case unavailable
    /// <#Description#>
    case serverError
    /// <#Description#>
    case unknown
}

// MARK: - LocalizedError

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidParameter:
            return "Request connect with invalid paramters"
        case .badRequest:
            return "Request connect error(Bad request)"
        case .authError:
            return "Auth Error"
        case .streamInitializeFailed:
            return "Stream initialize failed"
        case .nilResponse:
            return "Request response is nil"
        case .timeout:
            return "Request timeout"
        case .invalidMessageReceived:
            return "Invalid message has received"
        case .unavailable:
            return "Server status unavailable"
        case .serverError:
            return "server error"
        case .unknown:
            return "Unknown error occur"
        case .noSuitableResourceServer:
            return "No suitable resource server"
        }
    }
}
