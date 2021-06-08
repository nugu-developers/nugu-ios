//
//  ServerSideEventReceiver.swift
//  NuguCore
//
//  Created by childc on 2020/03/05.
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

import RxSwift

class ServerSideEventReceiver {
    private let apiProvider: NuguApiProvider
    private var pingDisposable: Disposable?
    private let stateSubject = PublishSubject<ServerSideEventReceiverState>()
    private let disposeBag = DisposeBag()
    
    /// Resource server array
    var serverPolicies = [Policy.ServerPolicy]()
    
    var state: ServerSideEventReceiverState = .disconnected() {
        didSet {
            if oldValue != state {
                log.debug("server side event receiver state changed from: \(oldValue) to: \(state)")
                stateSubject.onNext(state)
                state == .connected ? startPing() : stopPing()
            }
        }
    }
    
    init(apiProvider: NuguApiProvider) {
        self.apiProvider = apiProvider
    }

    var directive: Observable<MultiPartParser.Part> {
        state = .connecting

        var error: Error?
        return apiProvider.directive
            .take(1)
            .concatMap { [weak self] part -> Observable<MultiPartParser.Part> in
                guard let self = self else { return Observable.empty() }
                
                self.state = .connected
                return self.apiProvider.directive.startWith(part)
            }
            .retryWhen(retryDirective)
            .do(onError: {
                error = $0
            }, onDispose: { [weak self] in
                self?.state = .disconnected(error: error)
            })
    }

    var stateObserver: Observable<ServerSideEventReceiverState> {
        return stateSubject
    }
}

// MARK: - Retry policy

private extension ServerSideEventReceiver {
    func retryDirective(observer: Observable<Error>) -> Observable<Int> {
        return observer
            .enumerated()
            .flatMap { [weak self] (index, error) -> Observable<Int> in
                guard let self = self else { return Observable<Int>.empty() }
                log.error("recover network error: \(error), try count: \(index+1)")
                
                guard (error as? NetworkError) != NetworkError.authError else {
                    return Observable.error(error)
                }
                
                self.state = .connecting

                // if server policy does not exist, get it using `policies` api.
                guard 0 < self.serverPolicies.count else {
                    // The more try attempt, the more time to wait. But It is limited 180 seconds.
                    let waitTime = Int.random(in: 0...min(30*index, 180))
                    log.debug("retry \(waitTime) seconds later.")
                    return Observable<Int>.timer(.seconds(waitTime), scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
                        .take(1)
                        .flatMap { _ in self.apiProvider.policies }
                        .map { $0 as Policy? }
                        .catchError { _ in Observable<Policy?>.just(nil) }
                        .map {
                            guard let networkPolicies = $0 else { return index }

                            self.serverPolicies = networkPolicies.serverPolicies
                            let currentPolicy = self.serverPolicies.removeFirst()
                            self.apiProvider.loadBalancedUrl = "https://\(currentPolicy.hostname):\(currentPolicy.port)"
                            
                            return index
                        }
                }
                
                let policy = self.serverPolicies.removeFirst()
                self.apiProvider.loadBalancedUrl = "https://\(policy.hostname):\(policy.port)"
                return Observable<Int>.timer(.seconds(0), scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
                    .take(1)
        }
    }
}

// MARK: - ping

private extension ServerSideEventReceiver {
    func startPing() {
        let randomPingTime = Int.random(in: 180..<300)
        
        pingDisposable?.dispose()
        pingDisposable = Observable<Int>.interval(.seconds(randomPingTime), scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
            .flatMap { [weak self] _ -> Completable in
                guard let apiProvider = self?.apiProvider else {
                    return Completable.error(NetworkError.badRequest)
                }
                
                return apiProvider.ping
        }
        .retryWhen { (error: Observable<Error>) in
            error
                .enumerated()
                .flatMap { (index, error) -> Observable<Int> in
                    guard index < 3 else {
                        return Observable.error(error)
                    }
                    
                    return Observable<Int>.timer(.seconds(0), period: .seconds(Int.random(in: 10..<30)), scheduler: ConcurrentDispatchQueueScheduler(qos: .default)).take(1)
            }
        }
        .subscribe(onError: {
            log.error("Ping failed: \($0)")
        }, onDisposed: {
            log.debug("Ping schedule for server initiated directive is cancelled")
        })
        
        pingDisposable?.disposed(by: disposeBag)
        log.debug("Ping schedule for server initiated directive is set. It will be triggered \(randomPingTime) seconds later.")
    }
    
    func stopPing() {
        log.debug("Try to stop ping schedule")
        
        pingDisposable?.dispose()
        pingDisposable = nil
    }
}
