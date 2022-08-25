//
//  FakeContextManager.swift
//  NuguTests
//
//  Created by jaycesub on 2022/08/18.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
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

class FakeContextManager: ContextManageable {
    private var contextInfoProvider: ContextInfoProviderType?
    func addProvider(_ provider: @escaping ContextInfoProviderType) {
        contextInfoProvider = provider
    }
    
    func removeProvider(_ provider: @escaping ContextInfoProviderType) {
    }
    
    func getContexts(completion: @escaping ([ContextInfo]) -> Void) {
    }
    
    func getContexts(namespace: String, completion: @escaping ([ContextInfo]) -> Void) {
        contextInfoProvider? { contextInfo in
            guard let contextInfo = contextInfo else {
                completion([])
                return
            }
            completion([contextInfo])
        }
    }
}
