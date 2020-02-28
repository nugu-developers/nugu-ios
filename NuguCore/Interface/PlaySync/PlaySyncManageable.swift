//
//  PlaySyncManageable.swift
//  NuguCore
//
//  Created by MinChul Lee on 2019/07/17.
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

public protocol PlaySyncManageable: ContextInfoDelegate {
    /// Register `PlaySyncDelegate` to `PlaySyncManageable`.
    /// - Parameter delegate: The object to register.
    func add(delegate: PlaySyncDelegate)
    
    /// Unregister `PlaySyncDelegate` from `PlaySyncManageable`.
    /// - Parameter delegate: The object to unregister.
    func remove(delegate: PlaySyncDelegate)
    
    func startPlay(
        layerType: PlaySyncLayerType,
        contextType: PlaySyncContextType,
        duration: DispatchTimeInterval,
        playServiceId: String?,
        dialogRequestId: String
    )
    func endPlay(layerType: PlaySyncLayerType, contextType: PlaySyncContextType)
    func stopPlay(dialogRequestId: String)
    func resetTimer(layerType: PlaySyncLayerType, contextType: PlaySyncContextType)
}
