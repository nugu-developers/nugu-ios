//
//  ContextManager+Rx.swift
//  NuguAgents
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/10/27.
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

import NuguCore

import RxSwift

public extension ContextManageable {
    func rxContexts(namespace: String) -> Single<[ContextInfo]> {
        Single.create { [weak self] (observer) -> Disposable in
            guard let self = self else {
                observer(.failure(NuguAgentError.requestCanceled))
                return Disposables.create()
            }
            self.getContexts(namespace: namespace) { (contextInfo) in
                observer(.success(contextInfo))
            }
            return Disposables.create()
        }
    }
    
    func rxContexts() -> Single<[ContextInfo]> {
        Single.create { [weak self] (observer) -> Disposable in
            guard let self = self else {
                observer(.failure(NuguAgentError.requestCanceled))
                return Disposables.create()
            }
            self.getContexts { (contextInfo) in
                observer(.success(contextInfo))
            }
            return Disposables.create()
        }
    }
}
