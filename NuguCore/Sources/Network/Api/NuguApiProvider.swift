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

import NuguUtils

import RxSwift

class NuguApiProvider: NSObject {
    private let requestTimeout: TimeInterval
    private var candidateResourceServers: [String]?
    private var disposeBag = DisposeBag()
    private var sessionConfig: URLSessionConfiguration
    private let sessionQueue = OperationQueue()
    private let processorQueue = DispatchQueue(label: "com.skt.Romaine.nugu_api_provider.processor")
    private lazy var session: URLSession = URLSession(configuration: sessionConfig,
                                                      delegate: self,
                                                      delegateQueue: sessionQueue)
    @Atomic var loadBalancedUrl: String? {
        didSet {
            log.debug("loadBalancedUrl: \(loadBalancedUrl ?? "nil")")
        }
    }
    
    private var resourceServerAddress: String? {
        if isCSLBEnabled {
            return loadBalancedUrl
        } else {
            return NuguServerInfo.resourceServerAddress
        }
    }

    // handle response for upload task.
    @Atomic private var eventResponseProcessors = [URLSessionTask: EventResponseProcessor]()

    // handle received directives by server side event
    private var serverSideEventProcessor: ServerSideEventProcessor?
    
    // flag of client side load balanceing
    private var isCSLBEnabled = false {
        didSet {
            if oldValue != isCSLBEnabled {
                log.debug("client side load balancing: \(isCSLBEnabled)")
            }
            
            // To connect last resource server, Comment out clearing loadBalancedUrl codes below.
            // But it must be remained as a comment for history.
//            if oldValue == false, isCSLBEnabled == true {
//                loadBalancedUrl = nil
//            }
        }
    }
    
    /**
     Initiate NuguApiProvider
     - Parameter resourceServerUrl: resource server url.
     - Parameter registryServerUrl: server url for client load balancing
     - Parameter options: api options.
     */
    init(timeout: TimeInterval = 10.0) {
        sessionConfig = URLSessionConfiguration.ephemeral
        requestTimeout = timeout
        super.init()
    }
    
    private let internalPolicies: Single<Policy> = Single<URLRequest>.create { (event) -> Disposable in
        let disposable = Disposables.create()
        
        guard let header = NuguApi.policy.header else {
            event(.error(NetworkError.authError))
            return disposable
        }
        
        var urlComponent = URLComponents(string: NuguApi.policy.uri(baseUrl: NuguServerInfo.registryServerAddress))
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
        request.allHTTPHeaderFields = header
        
        event(.success(request))
        return disposable
    }
    .flatMap { $0.rxDataTask(urlSession: URLSession.shared) }
    .map { try JSONDecoder().decode(Policy.self, from: $0) }
    .asObservable()
    .share()
    .asSingle()
    
    private lazy var internalDirective: Observable<MultiPartParser.Part> = {
        var task: URLSessionDataTask?
        var error: Error?
        
        return Single<Observable<Data>>.create { [weak self] (single) -> Disposable in
            // reset error
            error = nil
            let disposable = Disposables.create()
            guard let self = self else { return disposable }
            
            self.processorQueue.async {
                guard let header = NuguApi.directives.header else {
                    single(.error(NetworkError.authError))
                    return
                }
                
                // enable client side load balance and find new resource server for directive and event both.
                self.isCSLBEnabled = true
                
                guard let resourceServerUrl = self.resourceServerAddress else {
                    single(.error(NetworkError.noSuitableResourceServer))
                    return
                }
                
                if self.serverSideEventProcessor == nil {
                    self.serverSideEventProcessor = ServerSideEventProcessor()
                    
                    // connect downstream.
                    guard let downstreamUrl = URL(string: NuguApi.directives.uri(baseUrl: resourceServerUrl)) else {
                        log.error("invailid url: \(NuguApi.directives.uri(baseUrl: resourceServerUrl))")
                        single(.error(NetworkError.noSuitableResourceServer))
                        return
                    }
                    
                    var downstreamRequest = URLRequest(url: downstreamUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Double.infinity)
                    downstreamRequest.httpMethod = NuguApi.directives.method.rawValue
                    downstreamRequest.allHTTPHeaderFields = header
                    task = self.session.dataTask(with: downstreamRequest)
                    task?.resume()
                    log.debug("directive request header:\n\(downstreamRequest.allHTTPHeaderFields?.description ?? "")\n")
                }
                
                single(.success(self.serverSideEventProcessor!.subject))
            }
            
            return disposable
        }
        .asObservable()
        .flatMap { $0 }
        .concatMap { [weak self] (data) -> Observable<MultiPartParser.Part> in
            guard let self = self,
                let serverSideEventProcessor = self.serverSideEventProcessor else {
                    return Observable.error(NetworkError.streamInitializeFailed)
            }

            return self.makePart(with: data, processor: serverSideEventProcessor)
        }
        .do(onError: {
            error = $0
        }, onDispose: { [weak self] in
            self?.processorQueue.async {
                self?.serverSideEventProcessor = nil
                task?.cancel()
                
                if error == nil {
                    self?.isCSLBEnabled = false
                }
            }
        })
        .share()
    }()
    
    private func makePart(with data: Data, processor: MultiPartProcessable) -> Observable<MultiPartParser.Part> {
        processor.data.append(data)
        
        var partObserver: Observable<MultiPartParser.Part?> {
            guard let parts = processor.parseData() else {
                return Observable<MultiPartParser.Part?>.just(nil)
            }
                       
            return Observable.from(parts)
        }
        
        return partObserver.compactMap { $0 }
    }
}

// MARK: - APIs

extension NuguApiProvider {
    /**
     Request to device gateway (resource server)
     */
    func events(boundary: String, httpHeaderFields: [String: String]?, inputStream: InputStream) -> Observable<MultiPartParser.Part> {
        var uploadTask: URLSessionUploadTask!
        
        return Single<Observable<Data>>.create { [weak self] (single) -> Disposable in
            let disposable = Disposables.create()
            guard let self = self else { return disposable }
            
            self.processorQueue.async {
                guard let header = NuguApi.events.header else {
                    single(.error(NetworkError.authError))
                    return
                }
                
                guard let resourceServerUrl = self.resourceServerAddress else {
                    single(.error(NetworkError.noSuitableResourceServer))
                    return
                }
                
                guard let urlComponent = URLComponents(string: NuguApi.events.uri(baseUrl: resourceServerUrl)),
                    let url = urlComponent.url else {
                        log.error("invailid url: \(NuguApi.events.uri(baseUrl: resourceServerUrl))")
                        single(.error(NetworkError.badRequest))
                        return
                }
                
                var streamRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: self.requestTimeout)
                streamRequest.httpMethod = NuguApi.events.method.rawValue
                streamRequest.allHTTPHeaderFields = header
                streamRequest.allHTTPHeaderFields?[HTTPConst.contentTypeKey] = HTTPConst.eventContentTypePrefix+boundary
                if let httpHeaderFields = httpHeaderFields {
                    streamRequest.allHTTPHeaderFields = streamRequest.allHTTPHeaderFields?.merged(with: httpHeaderFields)
                }
                
                log.debug("request url: \(url)")
                log.debug("request event header: \(streamRequest.allHTTPHeaderFields ?? [:])")
                
                uploadTask = self.session.uploadTask(withStreamedRequest: streamRequest)
                let eventResponse = EventResponseProcessor(inputStream: inputStream)
                self._eventResponseProcessors.mutate {
                    $0[uploadTask] = eventResponse
                }
                
                uploadTask.resume()
                single(.success(eventResponse.subject))
            }
            
            return disposable
        }
        .asObservable()
        .flatMap { $0 }
        .concatMap { [weak self] (data) -> Observable<MultiPartParser.Part> in
            guard let self = self,
                let processor = self.eventResponseProcessors[uploadTask] else {
                    return Observable.error(NetworkError.streamInitializeFailed)
            }
            
            return self.makePart(with: data, processor: processor)
        }
    }
    
    /**
     Find available device gateway (resource server)
    */
    var policies: Single<Policy> {
        return internalPolicies
    }
    
    /**
    Start to receive data which is not requested but sent by server. (server side event)
    */
    var directive: Observable<MultiPartParser.Part> {
        return internalDirective
    }
    
    /**
     Send ping data to keep stream of server side event
     */
    var ping: Completable {
        guard let baseUrl = resourceServerAddress,
              let pingUrl = URL(string: NuguApi.ping.uri(baseUrl: baseUrl)) else {
            log.error("no resource server url")
            return Completable.error(NetworkError.noSuitableResourceServer)
        }
        
        guard let header = NuguApi.ping.header else {
            return Completable.error(NetworkError.authError)
        }
        
        var request = URLRequest(url: pingUrl)
        request.httpMethod = NuguApi.ping.method.rawValue
        request.allHTTPHeaderFields = header
        
        return request.rxDataTask(urlSession: session)
            .asCompletable()
    }
}

// MARK: - URLSessionDelegate

extension NuguApiProvider: URLSessionDataDelegate, StreamDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        log.debug("didReceive response:\n\(response)\n")
        
        guard let processor: MultiPartProcessable = eventResponseProcessors[dataTask] ?? serverSideEventProcessor else {
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
        guard let processor = eventResponseProcessors[task] else {
            log.error("Can't send an event. Unknown URLSessionTask requested input stream")
            return
        }
        
        guard processor.inputStream.streamStatus == .notOpen else {
            log.error("Can't send an event. Input stream was opened before")
            processor.subject.onError(NetworkError.streamInitializeFailed)
            return
        }
        
        completionHandler(processor.inputStream)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        (eventResponseProcessors[dataTask]?.subject ?? serverSideEventProcessor?.subject)?.onNext(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer {
            processorQueue.async { [weak self] in
                self?.eventResponseProcessors.keys.contains(task) == true ? (self?.eventResponseProcessors[task] = nil) : (self?.serverSideEventProcessor = nil)
            }
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
