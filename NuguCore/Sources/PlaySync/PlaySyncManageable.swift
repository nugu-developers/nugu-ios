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
        property: PlaySyncProperty,
        info: PlaySyncInfo
    )
    func endPlay(property: PlaySyncProperty)
    func stopPlay(dialogRequestId: String)
    
    /// Start new timer to release `PlaySyncProperty`.
    ///
    /// - Parameters:
    ///   - property: The object to release by timer.
    ///   - duration: The duration for timer.
    func startTimer(property: PlaySyncProperty, duration: TimeIntervallic)
    
    /// Restart exist timer to release `PlaySyncProperty`.
    ///
    /// If the timer for `PlaySyncProperty` not exist then `resetTimer` call ignored.
    /// - Parameter property: The object to release by timer.
    func resetTimer(property: PlaySyncProperty)
    
    /// Stop and remove exist timer to release `PlaySyncProperty`.
    ///
    /// - Parameter property: The object to release by timer.
    func cancelTimer(property: PlaySyncProperty)
    
    /// Hold timer until `resumeTimer` is called.
    ///
    /// - Parameter property: The object to pause timer.
    func pauseTimer(property: PlaySyncProperty)
    
    /// Resume timers paused by'pauseTimer'.
    ///
    /// - Parameter property: The object to resume timer.
    func resumeTimer(property: PlaySyncProperty)
}
