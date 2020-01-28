//
//  NuguCoreApiProvider.swift
//  NuguCore
//
//  Created by childc on 2019/09/26.
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

class NuguApiProvider: NSObject {
    private let url: String
    private var sessionConfig: URLSessionConfiguration
    private let sessionQueue = OperationQueue()
    private lazy var session: URLSession = URLSession(configuration: sessionConfig,
                                                      delegate: self,
                                                      delegateQueue: sessionQueue)
    
    private var recvData = Data()
    private var parser: MultiPartParser?
    private var directiveTask: URLSessionDataTask?
    private var directiveSubject: PublishSubject<MultiPartParser.Part>?
    
    private var disposeBag = DisposeBag()
    
    init(url: String, timeout: TimeInterval = 30.0) {
        self.url = url + "/v1"
        sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = timeout
        
        super.init()
    }
    
    deinit {
        directiveSubject?.dispose()
    }
    
    static var policies: Single<Policy> {
        var urlSession: URLSession! = URLSession(configuration: .default)
        
        var urlComponent = URLComponents(string: (NuguServerInfo.registryAddress + NuguApi.policy.path))
        urlComponent?.queryItems = [
            URLQueryItem(name: "protocol", value: "H2")
        ]
        
        guard let url = urlComponent?.url else {
            log.error(NetworkError.invalidParameter)
            return Single.error(NetworkError.invalidParameter)
        }
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        request.httpMethod = NuguApi.policy.method.rawValue
        request.allHTTPHeaderFields = NuguApi.policy.header
        
        return request.rxDataTask(urlSession: urlSession)
            .map { data -> Policy in
                try JSONDecoder().decode(Policy.self, from: data)
        }
        .do(onDispose: {
            urlSession = nil
        })
    }
    
    var directive: Observable<MultiPartParser.Part> {
        return Single<Observable<MultiPartParser.Part>>.create { [weak self] (single) -> Disposable in
            let disposable = Disposables.create()
            
            guard let self = self else { return disposable }
            
            if self.directiveTask?.state != .running || self.directiveSubject == nil {
                self.directiveSubject?.dispose()
                self.directiveTask?.cancel()
                self.directiveSubject = PublishSubject<MultiPartParser.Part>()
                
                // connect downstream.
                guard let downstreamUrl = URL(string: self.url+"/"+NuguApi.directives.path) else {
                    log.error("invailid url: \(self.url+"/"+NuguApi.directives.path)")
                    single(.error(NetworkError.badRequest))
                    return disposable
                }
                
                var downstreamRequest = URLRequest(url: downstreamUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Double.infinity)
                downstreamRequest.httpMethod = NuguApi.directives.method.rawValue
                downstreamRequest.allHTTPHeaderFields = NuguApi.directives.header
                self.directiveTask = self.session.dataTask(with: downstreamRequest)
                self.directiveTask!.resume()
                log.debug("directive request header:\n\(downstreamRequest.allHTTPHeaderFields?.description ?? "")\n")
            }
            
            single(.success(self.directiveSubject!))
            return disposable
        }
        .asObservable()
        .flatMap { $0 }
    }
    
    var ping: Completable {
        guard let url = URL(string: self.url+"/"+NuguApi.ping.path) else {
            log.error("invailid url: \(self.url+"/"+NuguApi.ping.path)")
            return Completable.error(NetworkError.badRequest)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = NuguApi.ping.method.rawValue
        request.allHTTPHeaderFields = NuguApi.ping.header
        
        return request.rxDataTask(urlSession: session)
            .asCompletable()
    }
    
    func disconnect() {
        session.invalidateAndCancel()
    }
}

// MARK: - NuguApiProvider

extension NuguApiProvider: NuguApiProvidable {
    func request(with nuguApiRequest: NuguApiRequest, completion: ((Result<Data, Error>) -> Void)?) {
        guard var urlComponent = URLComponents(string: self.url+"/"+nuguApiRequest.path) else {
            log.error("invailid url: \(self.url+"/"+nuguApiRequest.path)")
            completion?(.failure(NetworkError.badRequest))
            return
        }
        urlComponent.queryItems = nuguApiRequest.queryItems.map({ (key, value) -> URLQueryItem in
            URLQueryItem(name: key, value: value)
        })
        guard let url = urlComponent.url else {
            log.error("invailid parameter: \(urlComponent.queryItems ?? [])")
            completion?(.failure(NetworkError.invalidParameter))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = nuguApiRequest.method
        request.allHTTPHeaderFields = nuguApiRequest.header
        
        request.rxUploadTask(urlSession: session, data: nuguApiRequest.bodyData)
            .subscribe(onSuccess: { data in
                log.debug("message was sent successfully")
                completion?(.success(data))
            }, onError: { error in
                log.error(error)
                completion?(.failure(error))
            }).disposed(by: disposeBag)
    }
}

// MARK: - URLSessionDelegate

extension NuguApiProvider: URLSessionDataDelegate, StreamDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        log.debug("didReceive response:\n\(response)\n")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            directiveSubject?.onError(NetworkError.streamInitializeFailed)
            disconnect()
            return
        }
        
        switch HTTPStatusCode(rawValue: httpResponse.statusCode) {
        case .ok: // extract boundary and store it.
            guard let contentType = httpResponse.allHeaderFields["Content-Type"] as? String,
                contentType.contains("boundary="),
                let boundary = contentType.split(separator: "=")[safe: 1] else {
                    completionHandler(.cancel)
                    return
            }
            
            parser = MultiPartParser(boundary: String(boundary))
            completionHandler(.allow)
        case .unauthorized: // help the app. to re-authorize.
            directiveSubject?.onError(NetworkError.authError)
            fallthrough
        default:
            completionHandler(.cancel)
            disconnect()
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        recvData.append(data)
        parseRecvData()
    }
    
    private func parseRecvData() {
        guard let parser = parser else {
            return
        }
        
        do {
            let (parts, size) = parser.separateParts(data: recvData)
            guard 0 < size else { return }
            
            try parts.forEach { (data) in
                guard 0 < data.count else { return }
                
                let part = try parser.parse(data: data)
                directiveSubject?.onNext(part)
                
                log.debug("directive channel didReceived header:\n\(part.header), size: \(data.count)\n")
                log.debug("data:\n\(String(data: part.body, encoding: .utf8) ?? "<<recv data cannot be converted to string>>")\n")
            }
            
            recvData = recvData.subdata(in: size..<recvData.count)
        } catch {
            log.error("parser error:\n\(error)\ndata:\n\(String(data: recvData, encoding: .utf8) ?? "")\n")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            directiveSubject?.onError(NetworkError.unavailable)
            return
        }
        
        log.debug("directive channel didOccurError: \(error)")
        directiveSubject?.onError(error)
    }
}
