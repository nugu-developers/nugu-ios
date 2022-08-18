//
//  FakeContextManager.swift
//  NuguTests
//
//  Created by 신정섭님/A.출시 on 2022/08/18.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
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
