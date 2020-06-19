//
//  NuguLoginError.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 16/09/2019.
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

/// The `NuguLoginKitError` is error of `NuguLoginKit`
public enum NuguLoginKitError: Error {
    
    /// The `APIError` is error of API
    public enum APIError: Error {
        
        /// No has response
        case noResponse
        
        /// Failed to parsing by data (HTTP status-code is contains in 200-299)
        case parsingFailed(Data)
        
        /// Failed to serialization by data (HTTP status-code is not contains in 200-299)
        case serializationFailed(Data)
        
        /// The `urlSessionError` has occured from `URLSession`
        case urlSessionError(Error)
        
        /// Failed to validate status-code (HTTP status-code is not contains in 200-299)
        case invalidStatusCode(reason: APIErrorReason)
    }
    
    /// `OAuthManager` has no `loginTypeInfo`.
    case noLoginTypeInfo
    
    /// The URL to which are trying to send a request is invalid.
    case invalidRequestURL
    
    /// The URL received by AppDelegate is invalid.
    ///
    /// The error occurs when receive any URL other than redirectURI during OAuth authentication process.
    case invalidOpenURL
    
    /// The authorization-code received by `AppDelegate` is invalid.
    case noAuthorizationCode
    
    /// The state received by AppDelegate is invalid.
    case invalidState
    
    /// The error occurs when called `safariViewControllerDidFinish()` by `SFSafariViewControllerDelegate` during OAuth authentication process.
    case cancelled
    
    /// The error occurs when request OAuth authentication API.
    case apiError(error: APIError)
    
    /// The error occurs by unknown or complicated issue.
    case unknown(description: String?)
}

/// The `APIErrorReason` is the reason for the case where the `statusCode` is not 200-299.
public struct APIErrorReason {
    /// HTTP status code.
    public let statusCode: Int
    
    /// The `error` is an error for the authentication API.
    public let error: String?
    
    /// The `description` is description of error.
    public let description: String?
    
    /// The `urlResponse` is response from HTTP Request.
    public let urlResponse: HTTPURLResponse
    
    /// The `errorCode` is a code for the error.
    public let errorCode: String?
    
    /// The initializer for `APIErrorReason`.
    /// - Parameter error: The `error` is like error-code
    /// - Parameter description: The `description` is description of error
    /// - Parameter urlResponse: The `urlResponse` is response from HTTP Request
    /// - Parameter errorCode: The `errorCode` is a code for the error.
    init(
        error: String?,
        description: String?,
        errorCode: String?,
        urlResponse: HTTPURLResponse
    ) {
        self.error = error
        self.description = description
        self.errorCode = errorCode
        self.urlResponse = urlResponse
        self.statusCode = urlResponse.statusCode
    }
}
