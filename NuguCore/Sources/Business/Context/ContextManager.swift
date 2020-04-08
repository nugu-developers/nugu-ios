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

import RxSwift

public class ContextManager: ContextManageable {
    private let contextDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.context_manager", qos: .userInitiated)
    private lazy var contextScheduler = SerialDispatchQueueScheduler(
        queue: contextDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.context_manager"
    )
    
    private let provideContextDelegates = DelegateSet<ContextInfoDelegate>()
    
    private let disposeBag = DisposeBag()

    public init() {}
}

// MARK: - ContextManageable

extension ContextManager {
    public func add(delegate: ContextInfoDelegate) {
        provideContextDelegates.add(delegate)
    }

    public func remove(delegate: ContextInfoDelegate) {
        provideContextDelegates.remove(delegate)
    }
    
    public func getContexts(namespace: String, completion: @escaping ([ContextInfo]) -> Void) {
        getContexts { contextInfos in
            let filteredPayload = contextInfos.compactMap { (contextInfo) -> ContextInfo? in
                if contextInfo.contextType == .client || contextInfo.name == namespace {
                    return contextInfo
                } else {
                    // FIXME: 추후 서버에서 각 capability interface 정보를 저장하게 되면 제거해야 함.
                    if let payload = contextInfo.payload as? [String: AnyHashable] {
                        let versionPayload = payload.filter { $0.key == "version" }
                        return ContextInfo(contextType: contextInfo.contextType, name: contextInfo.name, payload: versionPayload)
                    } else {
                        return contextInfo
                    }
                }
            }

            completion(filteredPayload)
        }
    }
    
    public func getContexts(completion: @escaping ([ContextInfo]) -> Void) {
        var requests = [Single<ContextInfo?>]()
        provideContextDelegates.notify { delegate in
            requests.append(getContext(delegate: delegate))
        }
        
        Single<ContextInfo?>.zip(requests)
            .subscribeOn(contextScheduler)
            .map({ (contextInfos) -> [ContextInfo] in
                return contextInfos.compactMap({ $0 })
            })
            .subscribe(
                onSuccess: { (contextInfos) in
                    completion(contextInfos)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Private

private extension ContextManager {
    func getContext(delegate: ContextInfoDelegate) -> Single<ContextInfo?> {
        return Single<ContextInfo?>.create { event -> Disposable in
            delegate.contextInfoRequestContext { (contextInfo) in
                event(.success(contextInfo))
            }
            return Disposables.create()
        }
    }
}
