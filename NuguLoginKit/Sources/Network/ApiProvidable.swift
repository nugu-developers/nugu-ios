//
//  ApiProvidable.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 2020/06/05.
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

protocol ApiProvidable {
    var httpMethod: String { get }
    var headers: [String: String] { get }
    var uri: String { get }
    var bodyParams: [String: String] { get }
    
    @discardableResult
    func request(completion: ((Result<Data, NuguLoginKitError.APIError>) -> Void)?) -> URLSessionDataTask
}

// MARK: - Default method

extension ApiProvidable {
    @discardableResult
    func request(completion: ((Result<Data, NuguLoginKitError.APIError>) -> Void)?) -> URLSessionDataTask {
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
                        completion?(.success(data))
                    case (300..<400), (400..<500), (500..<600):
                        guard let jsonDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                            // Invalid JSON format
                            completion?(.failure(.serializationFailed(data)))
                            break
                        }
                        
                        let error = jsonDictionary["error"] as? String
                        let description = jsonDictionary["error_description"] as? String
                        let errorCode = jsonDictionary["code"] as? String
                        
                        // Known error format
                        completion?(.failure(.invalidStatusCode(reason: APIErrorReason(error: error, description: description, errorCode: errorCode, urlResponse: response))))
                    default:
                        // Unknown http-status-code
                        completion?(.failure(.invalidStatusCode(reason: APIErrorReason(error: nil, description: nil, errorCode: nil, urlResponse: response))))
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
