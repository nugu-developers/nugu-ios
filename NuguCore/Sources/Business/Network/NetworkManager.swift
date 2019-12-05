//
//  NetworkManager.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 08/07/2019.
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

public class NetworkManager: NetworkManageable {
    private var apiProvider: NuguApiProvider?
    private let disposeBag = DisposeBag()
    private let receiveMessageDelegates = DelegateSet<ReceiveMessageDelegate>()
    private let networkStatusDelegates = DelegateSet<NetworkStatusDelegate>()
    private var receiveDisposable: Disposable?
    private var pingDisposable: Disposable?
    
    public var networkStatus: NetworkStatus = .disconnected() {
        didSet {
            if oldValue != networkStatus {
                log.info("From:\(oldValue) To:\(networkStatus)")
                networkStatusDelegates.notify { (delegate) in
                    delegate.networkStatusDidChange(networkStatus)
                }
                
                switch networkStatus {
                case .connected:
                    startPing()
                case .disconnected:
                    stopPing()
                }
            }
        }
    }
    
    public var connected: Bool {
        return networkStatus == .connected
    }
    
    public init() {}
    
    public func connect(completion: ((Result<Void, Error>) -> Void)? = nil) {
        NuguApiProvider
            .policies
            .flatMapCompletable { [weak self] (policy) -> Completable in
                guard let self = self else {
                    return Completable.error(NetworkError.nilResponse)
                }
                
                return self.iterateSetEndPoint(with: policy.serverPolicies)
            }.subscribe(onCompleted: {
                self.receiveMessage()
                self.networkStatus = .connected
                completion?(.success(()))
            }, onError: { [weak self] (error) in
                completion?(.failure(error))
                self?.networkStatus = .disconnected(error: error)
            }).disposed(by: disposeBag)
    }
    
    // TODO: NetworkManageable 에 추가? 중복코드 제거.
    func connect(serverPolicies: [Policy.ServerPolicy], completion: ((Result<Void, Error>) -> Void)? = nil) {
        self.iterateSetEndPoint(with: serverPolicies)
            .subscribe(onCompleted: {
                self.receiveMessage()
                self.networkStatus = .connected
                completion?(.success(()))
            }, onError: { [weak self] (error) in
                completion?(.failure(error))
                self?.networkStatus = .disconnected(error: error)
            }).disposed(by: disposeBag)
    }

    public func disconnect() {
        apiProvider?.disconnect()
        apiProvider = nil
    }
    
    public func add(statusDelegate: NetworkStatusDelegate) {
        networkStatusDelegates.add(statusDelegate)
    }
    
    public func remove(statusDelegate: NetworkStatusDelegate) {
        networkStatusDelegates.remove(statusDelegate)
    }
    
    public func add(receiveMessageDelegate delegate: ReceiveMessageDelegate) {
        receiveMessageDelegates.add(delegate)
    }
    
    public func remove(receiveMessageDelegate delegate: ReceiveMessageDelegate) {
        receiveMessageDelegates.remove(delegate)
    }
}

extension NetworkManager: MessageSendable {
    public func send(upstreamEventMessage: UpstreamEventMessage, completion: ((SendMessageStatus) -> Void)?) {
        apiProvider?.event(upstreamEventMessage)
            .subscribe(onCompleted: {
                log.debug("message was sent successfully")
                completion?(.success)
            }, onError: { error in
                log.error(error)
                completion?(.error(error: error))
            }).disposed(by: disposeBag)
    }
    
    public func send(upstreamAttachment: UpstreamAttachment, completion: ((SendMessageStatus) -> Void)?) {
        apiProvider?.eventAttachment(upstreamAttachment)
            .subscribe(onCompleted: {
                log.debug("attachment was sent successfully")
                completion?(.success)
            }, onError: { error in
                log.error(error)
                completion?(.error(error: error))
            }).disposed(by: self.disposeBag)
    }
    
    public func send(crashReports: [CrashReport]) {
        apiProvider?.crash(reports: crashReports).subscribe().disposed(by: self.disposeBag)
    }
}

private extension NetworkManager {
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
    
    func receiveMessage() {
        guard let apiProvider = apiProvider else { return }

        receiveDisposable?.dispose()
        receiveDisposable = apiProvider.directive
            .subscribe(
                onNext: { [weak self] part in
                    self?.receiveMessageDelegates.notify { delegate in
                        delegate.receiveMessageDidReceive(header: part.header, body: part.body)
                    }
                },
                onError: { [weak self] error in
                    log.error("directive error: \(error)")
                    
                    guard (error as? NetworkError) != .authError else {
                        self?.networkStatus = .disconnected(error: error as? NetworkError)
                        return
                    }
                    
                    guard (error as NSError).code != NSURLErrorCancelled else {
                        self?.networkStatus = .disconnected()
                        return
                    }
                    
                    self?.connect()
                }, onCompleted: { [weak self] in
                    log.error("directive completed")
                    self?.networkStatus = .disconnected()
            })
        
        receiveDisposable?.disposed(by: disposeBag)
    }
    
}

// MARK: - Private (connect endpoint with policy)

private extension NetworkManager {
    func iterateSetEndPoint(with serverPolicies: [Policy.ServerPolicy]) -> Completable {
        return Completable.create(subscribe: { [weak self] (complete) -> Disposable in
            let disposable = Disposables.create()
            
            guard let self = self else { return disposable }
            
            Observable<Policy.ServerPolicy>
                .from(serverPolicies)
                .concatMap { self.setEndPoint(policy: $0) }
                .filter { $0 != nil }
                .take(1)
                .subscribe(onNext: { apiProvider in
                    self.apiProvider = apiProvider
                    complete(.completed)
                }, onError: { error in
                    complete(.error(error))
                }, onCompleted: {
                    guard self.apiProvider != nil else {
                        complete(.error(NetworkError.unavailable))
                        return
                    }
                }).disposed(by: self.disposeBag)
            
            return disposable
        })
    }
    
    func setEndPoint(policy: Policy.ServerPolicy) -> Single<NuguApiProvider?> {
        let apiProvider = NuguApiProvider(url: "https://" + "\(policy.address):\(policy.port)")
        return Completable.create { (completer) -> Disposable in
            let disposable = Disposables.create()
            
            apiProvider.directive
                .retryWhen { (error: Observable<Error>) -> Observable<Int> in
                    error
                        .enumerated()
                        .flatMap { (index, error) -> Observable<Int> in
                            guard let networkError = error as? NetworkError, networkError != .authError, index < policy.retryCountLimit else {
                                return Observable.error(error)
                            }
                            
                            return Observable<Int>.timer(RxTimeInterval.seconds(1), scheduler: ConcurrentDispatchQueueScheduler(qos: .default)).take(1)
                    }
            }
            .take(1)
            .subscribe(onNext: { (part) in
                log.debug("downstream is establisehd: \(part)")
                completer(.completed)
            }, onError: { (error) in
                completer(.error(error))
            }).disposed(by: self.disposeBag)
                
            return disposable
        }
        .andThen(Single<NuguApiProvider?>.just(apiProvider))
        .catchError { (error) -> PrimitiveSequence<SingleTrait, NuguApiProvider?> in
            guard (error as? NetworkError) != .authError else {
                return Single.error(error)
            }
            
            return Single<NuguApiProvider?>.just(nil)
        }
    }
}
