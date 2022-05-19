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
    
    private(set) var state: ServerSideEventReceiverState = .unconnected {
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
            .enumerated()
            .map { [weak self] (index: Int, element: MultiPartParser.Part) in
                if index == 0 {
                    // Change state when the first directive arrived
                    self?.state = .connected
                }
                
                return element
            }
            .do(onError: {
                error = $0
            }, onDispose: { [weak self] in
                if let error = error {
                    self?.state = .disconnected(error: error)
                    return
                }
                
                self?.state = .unconnected
            })
    }

    var stateObserver: Observable<ServerSideEventReceiverState> {
        return stateSubject
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
        .retry {  (error: Observable<Error>) in
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
