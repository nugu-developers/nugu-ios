//
//  NuguOAuthApi.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 2020/01/06.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

struct NuguOAuthApi {
    let clientId: String
    let clientSecret: String
    let deviceUniqueId: String
    let grantTypeInfo: GrantTypeInfo
    
    enum GrantTypeInfo {
        case authorizationCode(code: String, redirectUri: String)
        case refreshToken(refreshToken: String)
        case clientCredentials
    }
}

// MARK: - OAuth API Spec

extension NuguOAuthApi {
    var httpMethod: String {
        return "post"
    }
    
    var headers: [String: String] {
        return ["Content-Type": "application/x-www-form-urlencoded; charset=utf-8"]
    }
    
    var uri: String {
        return NuguOAuthServerInfo.serverBaseUrl + "/oauth/token"
    }
    
    var bodyParams: [String: String] {
        switch grantTypeInfo {
        case .authorizationCode(let code, let redirectUri):
            return [
                "grant_type": "authorization_code",
                "client_id": clientId,
                "client_secret": clientSecret,
                "code": code,
                "redirect_uri": redirectUri
            ]
        case .refreshToken(let refreshToken):
            return [
                "grant_type": "refresh_token",
                "client_id": clientId,
                "client_secret": clientSecret,
                "refresh_token": refreshToken
            ]
        case .clientCredentials:
            return [
                "grant_type": "client_credentials",
                "client_id": clientId,
                "client_secret": clientSecret,
                "data": "{\"deviceSerialNumber\":\"\(deviceUniqueId)\"}"
            ]
        }
    }
}

// MARK: - Provider

extension NuguOAuthApi {
    @discardableResult
    func request(completion: ((Result<AuthorizationInfo, NuguLoginKitError.APIError>) -> Void)?) -> URLSessionDataTask {
        // URLRequest
        let url = URL(string: self.uri)!
        var urlRequest = URLRequest(url: url)
        
        // HttpMethod
        urlRequest.httpMethod = self.httpMethod
        
        // Header
        self.headers.forEach { (header) in
            urlRequest.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        // Body
        urlRequest.httpBody = self.bodyParams.map { (parameter) -> String? in
            guard let encodedValue = parameter.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
            return "\(parameter.key)=\(encodedValue)"
        }
        .compactMap({ $0 })
        .joined(separator: "&")
        .data(using: .utf8)

        // Task
        let dataTask = URLSession.shared.dataTask(
            with: urlRequest,
            completionHandler: { (data, response, error) in
                switch (data, response, error) {
                case (_, _, let error?):
                    // URLSessionDataTask has error
                    completion?(.failure(.urlSessionError(error)))
                case (let data?, let response as HTTPURLResponse, _):
                    // Validate http-status-code
                    switch response.statusCode {
                    case (200..<300):
                        // Failed parsing
                        guard let authorizationInfo = try? JSONDecoder().decode(AuthorizationInfo.self, from: data) else {
                            completion?(.failure(.parsingFailed(data)))
                            break
                        }
                        
                        // Success
                        completion?(.success(authorizationInfo))
                    case (300..<400), (400..<500), (500..<600):
                        guard let jsonDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                            // Invalid JSON format
                            completion?(.failure(.serializationFailed(data)))
                            break
                        }
                        
                        let error = jsonDictionary["error"] as? String
                        let description = jsonDictionary["error_description"] as? String
                        
                        // Known error format
                        completion?(.failure(.invalidStatusCode(reason: APIErrorReason(error: error, description: description, urlResponse: response))))
                    default:
                        // Unknown http-status-code
                        completion?(.failure(.invalidStatusCode(reason: APIErrorReason(error: nil, description: nil, urlResponse: response))))
                    }
                default:
                    // No has response
                    completion?(.failure(.noResponse))
                }
        })
        
        dataTask.resume()
        return dataTask
    }
}
