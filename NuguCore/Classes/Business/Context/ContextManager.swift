//
//  ContextManager.swift
//  NuguCore
//
//  Created by MinChul Lee on 25/04/2019.
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

public class ContextManager: ContextManageable {
    private let contextDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.context_manager", qos: .userInitiated)
    private lazy var contextScheduler = SerialDispatchQueueScheduler(
        queue: contextDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.context_manager"
    )
    
    private let provideContextDelegates = DelegateSet<ProvideContextDelegate>()
    
    private var capabilityContextInfos = [String: ContextInfo]()
    private var clientContextInfos = [String: ContextInfo]()
    private var contextPayload: ContextPayload {
        return ContextPayload(
            supportedInterfaces: Array(capabilityContextInfos.values),
            client: Array(clientContextInfos.values)
        )
    }
    
    private let disposeBag = DisposeBag()

    public init() {
        log.info("")
    }

    deinit {
        log.info("")
    }
}

// MARK: - ContextManageable

extension ContextManager {
    public func add(provideContextDelegate delegate: ProvideContextDelegate) {
        provideContextDelegates.add(delegate)
    }

    public func remove(provideContextDelegate delegate: ProvideContextDelegate) {
        provideContextDelegates.remove(delegate)
    }

    public func set(context: ContextInfo) {
        switch context.contextType {
        case .capability:
            capabilityContextInfos[context.name] = context
        case .client:
            clientContextInfos[context.name] = context
        }
    }

    public func getContexts(completionHandler: @escaping (ContextPayload) -> Void) {
        var requests = [Completable]()
        provideContextDelegates.notify { delegate in
            requests.append(getContext(delegate: delegate))
        }
        
        Completable.zip(requests)
            .subscribeOn(contextScheduler)
            .do(
                onError: { [weak self] error in
                    guard let self = self else { return }
                    
                    log.error(error)
                    completionHandler(self.contextPayload)
                },
                onCompleted: { [weak self] in
                    guard let self = self else { return }
                    
                    completionHandler(self.contextPayload)
                }
            )
            .subscribe().disposed(by: disposeBag)
    }
}

// MARK: - Private

private extension ContextManager {
    func getContext(delegate: ProvideContextDelegate) -> Completable {
        return Completable.create { [weak self] event -> Disposable in
            if let context = delegate.provideContext() {
                self?.set(context: context)
            }

            event(.completed)
            return Disposables.create()
        }
    }
}
