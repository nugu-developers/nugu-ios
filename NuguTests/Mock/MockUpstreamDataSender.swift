//
//  MockUpstreamDataSender.swift
//  NuguTests
//
//  Created by 신정섭님/A.출시 on 2022/08/18.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
//

import Foundation

import NuguCore

class MockUpstreamDataSender: UpstreamDataSendable {
    var event: Upstream.Event?
    
    func sendEvent(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)?) {
        self.event = event
        completion?(.finished)
    }
    
    func sendStream(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)?) {
        self.event = event
        completion?(.finished)
    }
    
    func sendStream(_ attachment: Upstream.Attachment, completion: ((StreamDataState) -> Void)?) {
        // Nothing to do.
    }
    
    func cancelEvent(dialogRequestId: String) {
        // Nothing to do.
    }
}
