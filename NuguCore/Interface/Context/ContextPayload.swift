//
//  ContextPayload.swift
//  NuguCore
//
//  Created by MinChul Lee on 2019/07/15.
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

/// ContextPayload contains the contexts of the capability agents and the states of the client.
public struct ContextPayload {
    /// The contexts of the capability agents.
    public let supportedInterfaces: [ContextInfo]
    /// The states of the client.
    ///
    /// "wakeupWord" The keyword currently set in the KeywordDetector.
    /// "playStack" Play list managed by PlaySyncManager.
    public let client: [ContextInfo]
    
    public init(supportedInterfaces: [ContextInfo], client: [ContextInfo]) {
        self.supportedInterfaces = supportedInterfaces
        self.client = client
    }
}
