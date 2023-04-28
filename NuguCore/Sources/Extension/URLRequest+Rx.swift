//
//  URLRequest+Rx.swift
//  NuguCore
//
//  Created by MinChul Lee on 2019/12/11.
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

import RxSwift

extension URLRequest {
    func rxDataTask(urlSession: URLSession) -> Single<Data> {
        return Single<Data>.create { event -> Disposable in
            log.debug("url: \(self.url?.absoluteString ?? "")")
            let task = urlSession.dataTask(with: self) { (data, response, error) in
                guard error == nil else {
                    log.error("response error: \(error!)")
                    event(.failure(error!))
                    return
                }
                
                let result = self.urlTaskResponseParser(data: data, response: response, error: error)
                event(result)
            }
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    func rxUploadTask(urlSession: URLSession, data: Data) -> Single<Data> {
        return Single<Data>.create { event -> Disposable in
            log.debug("url: \(self.url?.absoluteString ?? "")")
            if let headers = self.allHTTPHeaderFields {
                log.debug("request header:\n\(headers)\n")
            }
            log.debug("body(\(data.count)):\n\(String(data: data, encoding: .utf8) ?? "")\n")

            let task = urlSession.uploadTask(with: self, from: data) { (data, response, error) in
                guard error == nil else {
                    log.error("response error: \(error!)")
                    event(.failure(error!))
                    return
                }
                
                let result = self.urlTaskResponseParser(data: data, response: response, error: error)
                event(result)
            }
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
    }
}

// MARK: - Private

private extension URLRequest {
    func urlTaskResponseParser(data: Data?, response: URLResponse?, error: Error?) -> SingleEvent<Data> {
        guard error == nil else {
            log.error(error!)
            return .failure(error!)
        }
        
        log.debug("response:\n\(response?.description ?? "")\n")
        guard let response = response as? HTTPURLResponse else {
            return .failure(NetworkError.nilResponse)
        }
        
        switch HTTPStatusCode(rawValue: response.statusCode) {
        case .ok:
            guard let data = data else {
                return .failure(NetworkError.invalidMessageReceived)
            }
            
            log.debug("data:\n\(String(data: data, encoding: .utf8) ?? "")\n")
            return .success(data)
        case .serverError:
            return .failure(NetworkError.serverError)
        case .unauthorized:
            return .failure(NetworkError.authError)
        default:
            return .failure(NetworkError.invalidMessageReceived)
        }
    }
}
