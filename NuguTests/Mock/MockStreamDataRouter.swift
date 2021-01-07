//
//  MockStreamDataRouter.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2020/02/11.
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

class MockStreamDataRouter: StreamDataRoutable {
    func addListener(_ listener: StreamDataListener) {
        
    }
    
    func remove(delegate: StreamDataListener) {
        
    }
    
    func startReceiveServerInitiatedDirective(completion: ((StreamDataState) -> Void)?) {
        
    }
    
    func startReceiveServerInitiatedDirective(to serverPolicy: Policy.ServerPolicy) {

    }
    
    func restartReceiveServerInitiatedDirective() {
        
    }
    
    func stopReceiveServerInitiatedDirective() {

    }
    
    func sendEvent(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)?) {
        
    }
    
    func sendStream(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)?) {
        
    }
    
    func sendStream(_ attachment: Upstream.Attachment, completion: ((StreamDataState) -> Void)?) {
        
    }
    
    func cancelEvent(dialogRequestId: String) {
        
    }
}
