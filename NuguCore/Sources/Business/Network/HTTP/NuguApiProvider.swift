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

import NuguInterface

import RxSwift

class NuguApiProvider: NSObject {
    private let url: String
    private var sessionConfig: URLSessionConfiguration
    private let sessionQueue = OperationQueue()
    private lazy var session: URLSession = URLSession(configuration: sessionConfig,
                                                      delegate: self,
                                                      delegateQueue: sessionQueue)
    
    private var recvBoundary: String? {
        didSet {
            guard let boundary = recvBoundary else {
                parser = nil
                return
            }
            
            parser = MultiPartParser(boundary: boundary)
        }
    }
    private var recvData = Data()
    private var parser: MultiPartParser?
    private var directiveTask: URLSessionDataTask?
    private let directiveQueue = DispatchQueue(label: "com.sktelecom.romaine.directive_queue")
    private let disposeBag = DisposeBag()
    private var directiveSubject: PublishSubject<MultiPartParser.Part>?
    
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
        
        return Single<Policy>.create { single -> Disposable in
            let disposable = Disposables.create()
            
            var urlComponent = URLComponents(string: (NuguServerInfo.registryAddress + NuguApi.policy.path))
            urlComponent?.queryItems = [
                URLQueryItem(name: "protocol", value: "H2")
            ]
            
            guard let url = urlComponent?.url else {
                log.error(NetworkError.invalidParameter)
                single(.error(NetworkError.invalidParameter))
                return disposable
            }
            
            var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
            request.httpMethod = NuguApi.policy.method.rawValue
            request.allHTTPHeaderFields = NuguApi.policy.header
            
            log.debug("url: \(request.url?.absoluteString ?? "")")
            urlSession.dataTask(with: request) { (data, response, error) in
                guard error == nil else {
                    log.error("get policies error: \(error!)")
                    single(.error(error!))
                    return
                }

                guard let recvData = data, 0 < recvData.count,
                    let policy = try? JSONDecoder().decode(Policy.self, from: recvData) else {
                        log.error("get policies data parsing failed:\n\(String(data: (data ?? Data()), encoding: .utf8) ?? "")\n")
                        single(.error(NetworkError.invalidMessageReceived))
                        urlSession = nil
                        return
                }
                
                log.debug("response:\n\(response?.description ?? "")\n")
                log.debug("data:\n\(String(data: recvData, encoding: .utf8) ?? "")\n")
                single(.success(policy))
                urlSession = nil
            }.resume()
            
            return disposable
        }
    }
    
    private func urlTaskResponseParser(data: Data?, response: URLResponse?, error: Error?) -> Result<Data, Error> {
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
            
            return .success(data)
        case .serverError:
            return .failure(NetworkError.serverError)
        case .unauthorized:
            return .failure(NetworkError.authError)
        default:
            return .failure(NetworkError.invalidMessageReceived)
        }
    }
    
    func event(_ upstream: UpstreamEventMessage) -> Completable {
        return Completable.create { [weak self] (complete) -> Disposable in
            let disposable = Disposables.create()
            
            guard let self = self else { return disposable }

            guard let url = URL(string: self.url+"/"+NuguApi.event.path) else {
                log.error("invailid url: \(self.url+"/"+NuguApi.event.path)")
                complete(.error(NetworkError.badRequest))
                return disposable
            }

            var request = URLRequest(url: url)
            request.httpMethod = NuguApi.event.method.rawValue
            request.allHTTPHeaderFields = NuguApi.event.header

            // body
            guard let bodyData = ("{ \"context\": \(upstream.contextString)"
                + ",\"event\": {"
                + "\"header\": \(upstream.headerString)"
                + ",\"payload\": \(upstream.payloadString) }"
                + " }").data(using: .utf8) else {
                    complete(.error(NetworkError.invalidParameter))
                    return disposable
            }

            log.debug("request header:\n\(request.allHTTPHeaderFields ?? [:])\n")
            log.debug("body:\n\(String(data: bodyData, encoding: .utf8) ?? "")\n")
            self.session.uploadTask(with: request, from: bodyData) { (data, response, error) in
                switch self.urlTaskResponseParser(data: data, response: response, error: error) {
                case .success:
                    complete(.completed)
                case .failure(let error):
                    complete(.error(error))
                }
            }.resume()

            return disposable
        }
    }
    
    func eventAttachment(_ upstream: UpstreamAttachment) -> Completable {
        return Completable.create { [weak self] (complete) -> Disposable in
            let disposable = Disposables.create()
            
            guard let self = self else { return disposable }
            
            var urlComponent = URLComponents(string: self.url+"/"+NuguApi.eventAttachment.path)
            urlComponent?.queryItems = [
                URLQueryItem(name: "User-Agent", value: NetworkConst.userAgent),
                URLQueryItem(name: "Content-Type", value: "application/octet-stream"),
                URLQueryItem(name: "namespace", value: upstream.header.namespace),
                URLQueryItem(name: "name", value: upstream.header.name),
                URLQueryItem(name: "dialogRequestId", value: upstream.header.dialogRequestId),
                URLQueryItem(name: "messageId", value: upstream.header.messageId),
                URLQueryItem(name: "version", value: upstream.header.version),
                URLQueryItem(name: "parentMessageId", value: upstream.header.messageId),
                URLQueryItem(name: "seq", value: String(upstream.seq)),
                URLQueryItem(name: "isEnd", value: upstream.isEnd ? "true" : "false")
            ]
            
            guard let url = urlComponent?.url else {
                log.error("invailid parameter: \(urlComponent?.queryItems ?? [])")
                complete(.error(NetworkError.invalidParameter))
                return disposable
            }

            var request = URLRequest(url: url)
            request.httpMethod = NuguApi.eventAttachment.method.rawValue
            request.allHTTPHeaderFields = NuguApi.eventAttachment.header
            
            // body
            log.debug("event request header:\n\(upstream.header)\n")
            log.debug("body:\n\(String(data: upstream.content, encoding: .ascii) ?? "")\n")
            
            self.session.uploadTask(with: request, from: upstream.content) { (data, response, error) in
                switch self.urlTaskResponseParser(data: data, response: response, error: error) {
                case .success:
                    complete(.completed)
                case .failure(let error):
                    complete(.error(error))
                }
            }.resume()
            
            return disposable
        }
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
    
    func crash(reports: [CrashReport]) -> Completable {
        return Completable.create { [weak self] (complete) -> Disposable in
            let disposable = Disposables.create()
            
            guard let self = self, let reportsData = try? JSONEncoder().encode(reports) else { return disposable }

            guard let url = URL(string: self.url+"/"+NuguApi.crashReport.path) else {
                log.error("invailid url: \(self.url+"/"+NuguApi.crashReport.path)")
                complete(.error(NetworkError.badRequest))
                return disposable
            }

            var request = URLRequest(url: url)
            request.httpMethod = NuguApi.crashReport.method.rawValue
            request.allHTTPHeaderFields = NuguApi.crashReport.header
            self.session.uploadTask(with: request, from: reportsData) { (data, response, error) in
                switch self.urlTaskResponseParser(data: data, response: response, error: error) {
                case .success:
                    complete(.completed)
                case .failure(let error):
                    complete(.error(error))
                }
            }.resume()
            
            return disposable
        }
    }
    
    var ping: Completable {
        return Completable.create { [weak self] (complete) -> Disposable in
            let disposable = Disposables.create()
            
            guard let self = self else { return disposable }
            
            guard let url = URL(string: self.url+"/"+NuguApi.ping.path) else {
                log.error("invailid url: \(self.url+"/"+NuguApi.ping.path)")
                complete(.error(NetworkError.badRequest))
                return disposable
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = NuguApi.ping.method.rawValue
            request.allHTTPHeaderFields = NuguApi.ping.header
            self.session.dataTask(with: request) { (data, response, error) in
                switch self.urlTaskResponseParser(data: data, response: response, error: error) {
                case .success:
                    complete(.completed)
                case .failure(let error):
                    complete(.error(error))
                }
            }.resume()
            return disposable
        }
    }
    
    func disconnect() {
        session.invalidateAndCancel()
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
            
            recvBoundary = String(boundary)
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
        guard let recvBoundary = recvBoundary,
            recvBoundary.count+2 < recvData.count,
            let parser = parser else {
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

// MARK: - ToBeDeleted

extension NuguApiProvider: URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
           let protectionSpace = challenge.protectionSpace
           guard protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
               let trustedURL = URL(string: url), let trustedHost = trustedURL.host,
               protectionSpace.host.contains(trustedHost) else {
                   completionHandler(.performDefaultHandling, nil)
                   return
           }
           
           guard let serverTrust = protectionSpace.serverTrust else {
               completionHandler(.performDefaultHandling, nil)
               return
           }
           
           completionHandler(.useCredential, URLCredential(trust: serverTrust))
       }
}
