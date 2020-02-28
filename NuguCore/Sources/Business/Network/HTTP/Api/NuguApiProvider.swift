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
    private var url: String?
    private var candidateResourceServers: [String]?
    private var disposeBag = DisposeBag()
    private var sessionConfig: URLSessionConfiguration
    private let sessionQueue = OperationQueue()
    private lazy var session: URLSession = URLSession(configuration: sessionConfig,
                                                      delegate: self,
                                                      delegateQueue: sessionQueue)

    // handle response for upload task.
    private var eventResponseProcessors = [URLSessionTask: EventResponseProcessor]()

    // handle received directives by server side event
    private var serverSideEventProcessor: ServerSideEventProcessor?
    
    // flag of client side load balanceing
    private var isCSLBEnabled: Bool
    
    /**
     Initiate NuguApiProvider
     - Parameter resourceServerUrl: resource server url.
     - Parameter registryServerUrl: server url for client load balancing
     - Parameter options: api options.
     */
    init?(resourceServerUrl: String? = nil, registryServerUrl: String? = nil, options: NuguApiProviderOptions? = nil) {
        switch options {
        case [.receiveServerSideEvent, .chargingFree]:
            guard let registryServerUrl = registryServerUrl else {
                return nil
            }

            url = nil
            NuguServerInfo.registryAddress = registryServerUrl
            
        case [.chargingFree]:
            guard let resourceServerUrl = resourceServerUrl else {
                return nil
            }
            
            url = resourceServerUrl

        case [.receiveServerSideEvent]:
            url = nil
            
        default:
            url = "https://fill.me:port"
        }
        
        isCSLBEnabled = options?.contains(.receiveServerSideEvent) ?? false
        sessionConfig = URLSessionConfiguration.ephemeral
        super.init()
    }
    
    /**
     Find available device gateway (resource server)
    */
    let policies: Single<Policy> = Single<URLRequest>.create { (event) -> Disposable in
        let disposable = Disposables.create()
        
        var urlComponent = URLComponents(string: (NuguServerInfo.registryAddress + NuguApi.policy.path))
        urlComponent?.queryItems = [
            URLQueryItem(name: "protocol", value: "H2")
        ]
        
        guard let url = urlComponent?.url else {
            log.error(NetworkError.invalidParameter)
            event(.error(NetworkError.invalidParameter))
            return disposable
        }
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        request.httpMethod = NuguApi.policy.method.rawValue
        request.allHTTPHeaderFields = NuguApi.policy.header
        
        event(.success(request))
        return disposable
    }
    .asObservable()
    .flatMap { $0.rxDataTask(urlSession: URLSession.shared) }
    .map { try JSONDecoder().decode(Policy.self, from: $0) }
    .share()
    .asSingle()
}

// MARK: - Retry policy

private extension NuguApiProvider {
    var chooseResourceServer: Observable<Int> {
        return Observable<Int>.create { [weak self] (observer) -> Disposable in
            let disposable = Disposables.create()
            guard let self = self else { return disposable }
            
            if let candidateResourceServers = self.candidateResourceServers,
                1 < candidateResourceServers.count {
                self.url = candidateResourceServers[0]
                self.candidateResourceServers?.remove(at: 0)
                
                observer.onNext(self.candidateResourceServers?.count ?? 0)
                return disposable
            }
            
            self.policies
                .subscribe(onSuccess: { (policy) in
                    self.candidateResourceServers = policy.serverPolicies
                        .map { "https://" + "\($0.hostname):\($0.port)" }
                    self.url = self.candidateResourceServers?[0]
                    self.candidateResourceServers?.remove(at: 0)
                    observer.onNext(self.candidateResourceServers?.count ?? 0)
                }, onError: { (error) in
                    observer.onError(error)
                })
                .disposed(by: self.disposeBag)
            
            return disposable
        }
    }
    
    func retry(observer: Observable<Error>) -> Observable<Int> {
        return observer
            .enumerated()
            .flatMap { [weak self] (index, error) -> Observable<Int> in
                guard self?.isCSLBEnabled == true else {
                    guard index < 3 else {
                        return Observable.error(NetworkError.unavailable)
                    }
                    
                    return Observable<Int>.timer(.seconds(1), scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
                        .take(1)
                }
                
                guard let self = self else {
                    return Observable.error(NetworkError.unavailable)
                }
                
                guard let error = error as? NetworkError else {
                    return self.chooseResourceServer
                }
                
                if error == NetworkError.noSuitableResourceServer {
                    return self.chooseResourceServer
                }
                
                return Observable.error(NetworkError.unavailable)
        }
    }
}

// MARK: - APIs

extension NuguApiProvider {
    /**
     Request to device gateway (resource server)
     */
    func events(inputStream: InputStream) -> Observable<MultiPartParser.Part> {
        var uploadTask: URLSessionUploadTask!
        
        return Single<Observable<Data>>.create { [weak self] (single) -> Disposable in
            let disposable = Disposables.create()

            guard let self = self else { return disposable }
            guard let resourceServerUrl = self.url else {
                single(.error(NetworkError.noSuitableResourceServer))
                return disposable
            }

            guard let urlComponent = URLComponents(string: resourceServerUrl+"/"+NuguApi.events.path),
                let url = urlComponent.url else {
                    log.error("invailid url: \(resourceServerUrl+"/"+NuguApi.events.path)")
                    single(.error(NetworkError.badRequest))
                    return disposable
            }
            
            var streamRequest = URLRequest(url: url)
            streamRequest.httpMethod = NuguApi.events.method.rawValue
            streamRequest.allHTTPHeaderFields = NuguApi.events.header
            
            log.debug("request url: \(url)")
            log.debug("request event header: \(streamRequest.allHTTPHeaderFields ?? [:])")
            
            uploadTask = self.session.uploadTask(withStreamedRequest: streamRequest)
            uploadTask.resume()
            
            let eventResponse = EventResponseProcessor(inputStream: inputStream)
            self.eventResponseProcessors[uploadTask] = eventResponse
            
            single(.success(eventResponse.subject))
            return disposable
        }
        .asObservable()
        .flatMap { $0 }
        .concatMap { [weak self] (data) -> Observable<MultiPartParser.Part?> in
            guard let self = self,
                var eventResponse = self.eventResponseProcessors[uploadTask] else {
                    return Observable.error(NetworkError.streamInitializeFailed)
            }
            
            eventResponse.data.append(data)
            guard let parts = eventResponse.parseData() else {
                return Observable<MultiPartParser.Part?>.just(nil)
            }
            
            return Observable.from(parts)
        }
        .compactMap { $0 }
        .retryWhen(retry)
    }
    
    /**
     Start to receive data which is not requested but sent by server. (server side event)
     */
    var directive: Observable<MultiPartParser.Part> {
        return Single<Observable<Data>>.create { [weak self] (single) -> Disposable in
            let disposable = Disposables.create()
            
            guard let self = self else { return disposable }
            guard let resourceServerUrl = self.url else {
                single(.error(NetworkError.noSuitableResourceServer))
                return disposable
            }
            
            if self.serverSideEventProcessor == nil {
                self.serverSideEventProcessor = ServerSideEventProcessor()
                
                // enable client side load balance and find new resource server for directive and event both.
                if self.isCSLBEnabled == false {
                    self.isCSLBEnabled = true
                    self.url = nil
                }
                
                // connect downstream.
                guard let downstreamUrl = URL(string: resourceServerUrl+"/"+NuguApi.directives.path) else {
                    log.error("invailid url: \(resourceServerUrl+"/"+NuguApi.directives.path)")
                    single(.error(NetworkError.noSuitableResourceServer))
                    return disposable
                }
                
                var downstreamRequest = URLRequest(url: downstreamUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Double.infinity)
                downstreamRequest.httpMethod = NuguApi.directives.method.rawValue
                downstreamRequest.allHTTPHeaderFields = NuguApi.directives.header
                self.session.dataTask(with: downstreamRequest).resume()
                log.debug("directive request header:\n\(downstreamRequest.allHTTPHeaderFields?.description ?? "")\n")
            }
            
            single(.success(self.serverSideEventProcessor!.subject))
            return disposable
        }
        .asObservable()
        .flatMap { $0 }
        .concatMap { [weak self] (data) -> Observable<MultiPartParser.Part?> in
            self?.serverSideEventProcessor?.data.append(data)
            guard let parts = self?.serverSideEventProcessor?.parseData() else {
                return Observable<MultiPartParser.Part?>.just(nil)
            }
            
            return Observable.from(parts)
        }
        .compactMap { $0 }
        .retryWhen(retry)
    }
    
    /**
     Send ping data to keep stream of server side event
     */
    var ping: Completable {
        guard let url = url,
            let pingUrl = URL(string: url+"/"+NuguApi.ping.path) else {
                log.error("no resource server url")
                return Completable.error(NetworkError.noSuitableResourceServer)
        }
        
        var request = URLRequest(url: pingUrl)
        request.httpMethod = NuguApi.ping.method.rawValue
        request.allHTTPHeaderFields = NuguApi.ping.header
        
        return request.rxDataTask(urlSession: session)
            .asCompletable()
            .retryWhen(retry)
    }
    
    /**
     Stop receive server side event
     */
    func disconnect() {
        serverSideEventProcessor = nil
    }
}

// MARK: - URLSessionDelegate

extension NuguApiProvider: URLSessionDataDelegate, StreamDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        log.debug("didReceive response:\n\(response)\n")
        
        guard var processor: MultiPartProcessable = eventResponseProcessors[dataTask] ?? serverSideEventProcessor else {
            log.error("unknown response: \(response)")
            completionHandler(.cancel)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            log.error("received response is not HTTPURLResponse")
            processor.subject.onError(NetworkError.invalidMessageReceived)
            completionHandler(.cancel)
            return
        }
        
        switch HTTPStatusCode(rawValue: httpResponse.statusCode) {
        case .ok:
            // Extract boundary and store it.
            guard let contentType = httpResponse.allHeaderFields["Content-Type"] as? String,
                contentType.contains("boundary="),
                let boundary = contentType.split(separator: "=")[safe: 1] else {
                    // All of responses must be multiPart data. if not, We'wll ignore it.
                    log.error("no multipart delemeter.")
                    completionHandler(.cancel)
                    processor.subject.onError(NetworkError.invalidMessageReceived)
                    return
            }
            
            processor.parser = MultiPartParser(boundary: String(boundary))
            completionHandler(.allow)
            
        case .unauthorized:
            // help the app. to re-authorize.
            processor.subject.onError(NetworkError.authError)
            completionHandler(.cancel)
        default:
            processor.subject.onError(NetworkError.unknown)
            completionHandler(.cancel)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        guard let inputStream = eventResponseProcessors[task]?.inputStream else {
            log.error("unknown URLSessionTask requested input stream")
            completionHandler(nil)
            return
        }
        
        completionHandler(inputStream)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        (eventResponseProcessors[dataTask]?.subject ?? serverSideEventProcessor?.subject)?.onNext(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer {
            eventResponseProcessors.keys.contains(task) ? (eventResponseProcessors[task] = nil) : (serverSideEventProcessor = nil)
        }
        
        let processor: MultiPartProcessable? = eventResponseProcessors[task] ?? serverSideEventProcessor
        if let error = error {
            log.debug("didCompleteWithError: \(error)")
            processor?.subject.onError(error)
            return
        }
        
        processor?.subject.onCompleted()
    }
}
