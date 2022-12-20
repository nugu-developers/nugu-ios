//
//  DummyStreamDataRouter.swift
//  NuguTests
//
//  Created by jaycesub on 2022/08/17.
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

class DummyStreamDataRouter: StreamDataRoutable {
    func startReceiveServerInitiatedDirective(completion: ((StreamDataState) -> Void)?) {
        // Nothing to do.
    }
    
    func startReceiveServerInitiatedDirective(to serverPolicy: Policy.ServerPolicy) {
        // Nothing to do.
    }
    
    func restartReceiveServerInitiatedDirective() {
        // Nothing to do.
    }
    
    func stopReceiveServerInitiatedDirective() {
        // Nothing to do.
    }
    
    func sendEvent(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)?) {
        // Nothing to do.
    }
    
    func cancelEvent(dialogRequestId: String) {
        // Nothing to do.
    }
    
    func sendStream(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)?) {
        // Nothing to do.
    }
    
    func sendStream(_ attachment: Upstream.Attachment, completion: ((StreamDataState) -> Void)?) {
        // Nothing to do.
    }
}
