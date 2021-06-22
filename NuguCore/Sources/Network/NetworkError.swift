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

/// An error that occurs while processing network request.
public enum NetworkError: Error {
    /// An error occurred due to a failure to connect to the registry server.
    ///
    /// This error only occurs when using connection-oriented feature..
    case noSuitableRegistryServer
    
    /// An error occurred due to a failure to connect to the server.
    case noSuitableResourceServer
    
    /// An error occurred due to a failure to connect to the server.
    ///
    /// This error only occurs when using connection-oriented feature
    case invalidParameter
    
    /// An error occurred due to a failure to connect to the server.
    ///
    /// This error only occurs when using connection-oriented feature
    case badRequest
    
    /// Rejected due to authorization error.
    case authError
    
    /// An error occurred due to a failure to open `InputSteram`.
    case streamInitializeFailed
    
    /// No has response.
    case nilResponse
    
    /// The request timed out.
    case timeout
    
    /// An error occurred while processing received data.
    case invalidMessageReceived
    
    /// The error occurs on the server.
    case serverError
    
    /// The error occurs by unknown or complicated issue.
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
        case .serverError:
            return "server error"
        case .unknown:
            return "Unknown error occur"
        case .noSuitableResourceServer:
            return "No suitable resource server"
        case .noSuitableRegistryServer:
            return "No suitable registry server"
        }
    }
}
