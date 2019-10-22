//
//  Type2Api.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 13/09/2019.
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

struct Type2Api {
    @discardableResult
    func getToken(
        serverBaseUrl: String,
        clientId: String,
        clientSecret: String,
        deviceSerialNumber: String?,
        completion: @escaping (Swift.Result<AuthorizationInfo, Error>) -> Void
        ) -> URLSessionDataTask {
        // URLRequest
        let url = URL(string: serverBaseUrl + "/oauth/token")!
        var urlRequest = URLRequest(url: url)
        
        // Method
        urlRequest.httpMethod = "post"
        
        // Header
        urlRequest.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        // Body
        var parameters = [
            "grant_type": "client_credentials",
            "client_id": clientId,
            "client_secret": clientSecret,
            //"scope":"?"
        ]
        
        if let deviceSerialNumber = deviceSerialNumber {
            parameters["data"] = "{\"deviceSerialNumber\":\"\(deviceSerialNumber)\"}"
        }
        
        urlRequest.httpBody = parameters
            .map { (parameter) -> String? in
                guard let encodedValue = parameter.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
                return "\(parameter.key)=\(encodedValue)"
            }
            .compactMap({ $0 })
            .joined(separator: "&")
            .data(using: .utf8)
        
        // Task
        let dataTask = URLSession.shared.dataTask(
            with: urlRequest,
            completionHandler: { (data, _, error) in
                if let tokenError = error {
                    completion(.failure(tokenError))
                    return
                }
                
                let result = Swift.Result<AuthorizationInfo, Error> {
                    guard let data = data else { throw ApiError.nilValue(description: "data is nil") }
                    return try JSONDecoder().decode(AuthorizationInfo.self, from: data)
                }
                
                completion(result)
        })
        
        // Resume created task
        dataTask.resume()
        
        return dataTask
    }
}
