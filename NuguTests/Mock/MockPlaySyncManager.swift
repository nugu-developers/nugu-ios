//
//  MockPlaySyncManager.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2020/03/02.
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

import NuguCore

class MockPlaySyncManager: PlaySyncManageable {
    func add(delegate: PlaySyncDelegate) {
        //
    }
    
    func remove(delegate: PlaySyncDelegate) {
        //
    }
    
    func startPlay(property: PlaySyncProperty, duration: DispatchTimeInterval, playServiceId: String?, dialogRequestId: String) {
        //
    }
    
    func endPlay(property: PlaySyncProperty) {
        //
    }
    
    func stopPlay(dialogRequestId: String) {
        //
    }
    
    func startTimer(property: PlaySyncProperty, duration: DispatchTimeInterval) {
        //
    }
    
    func resetTimer(property: PlaySyncProperty) {
        //
    }
    
    func cancelTimer(property: PlaySyncProperty) {
        //
    }
    
    func contextInfoRequestContext(completionHandler: @escaping (ContextInfo?) -> Void) {
        completionHandler(nil)
    }
}
