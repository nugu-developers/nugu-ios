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
    private let networkSubject = PublishSubject<NetworkStatus>()
    private lazy var directive = apiProvider.directive.share()
    private let disposeBag = DisposeBag()
    
    var networkStatus: NetworkStatus = .disconnected() {
        didSet {
            if oldValue != networkStatus {
                log.info("From:\(oldValue) To:\(networkStatus)")

                networkSubject.onNext(networkStatus)
                networkStatus == .connected ? startPing() : stopPing()
            }
        }
    }
    
    var isConnected: Bool {
        return networkStatus == .connected
    }
    
    init(apiProvider: NuguApiProvider) {
        self.apiProvider = apiProvider
    }
    
    var serverSideEvent: Observable<MultiPartParser.Part> {
        return Single<Observable<MultiPartParser.Part>>.create { [weak self] (event) -> Disposable in
            let disposable = Disposables.create()
            
            guard let self = self else { return disposable }
            
            self.directive
                .take(1)
                .subscribe(onNext: { (part) in
                    log.debug("downstream is establisehd. consume connection data blow:\n\(part)")
                    self.networkStatus = .connected
                    event(.success(self.directive))
                }, onError: { (error) in
                    event(.error(error))
                })
                .disposed(by: self.disposeBag)
            
            return disposable
        }
        .asObservable()
        .flatMap { $0 }
    }
    
    var networkObserver: Observable<NetworkStatus> {
        return networkSubject
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
        .subscribe()
        
        pingDisposable?.disposed(by: disposeBag)
    }
    
    func stopPing() {
        pingDisposable?.dispose()
        pingDisposable = nil
    }
}
