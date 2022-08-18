//
//  DummyStreamDataRouter.swift
//  NuguTests
//
//  Created by 신정섭님/A.출시 on 2022/08/17.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
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
