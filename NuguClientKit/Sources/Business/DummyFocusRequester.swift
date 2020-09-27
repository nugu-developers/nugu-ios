//
//  DummyFocusRequester.swift
//  NuguClientKit
//
//  Created by MinChul Lee on 2020/09/27.
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
import NuguCore

class DummyFocusRequester {
    private let focusManager: FocusManageable
    private let directiveSequener: DirectiveSequenceable
    private let streamDataRouter: StreamDataRoutable
    
    init(focusManager: FocusManageable, directiveSequener: DirectiveSequenceable, streamDataRouter: StreamDataRoutable) {
        self.focusManager = focusManager
        self.directiveSequener = directiveSequener
        self.streamDataRouter = streamDataRouter
        
        focusManager.add(channelDelegate: self)
        directiveSequener.add(delegate: self)
        streamDataRouter.add(delegate: self)
    }
}

extension DummyFocusRequester: FocusChannelDelegate {
    func focusChannelPriority() -> FocusChannelPriority {
        .background
    }
    
    func focusChannelDidChange(focusState: FocusState) {}
}

extension DummyFocusRequester: DirectiveSequencerDelegate {
    func directiveSequencerWillHandle(directive: Downstream.Directive, blockingPolicy: BlockingPolicy) {
    }
    
    func directiveSequencerDidHandle(directive: Downstream.Directive, result: DirectiveHandleResult) {
    }
}

extension DummyFocusRequester: StreamDataDelegate {
    func streamDataDidReceive(direcive: Downstream.Directive) {
    }
    
    func streamDataDidReceive(attachment: Downstream.Attachment) {
    }
    
    func streamDataWillSend(event: Upstream.Event) {
    }
    
    func streamDataDidSend(event: Upstream.Event, error: Error?) {
    }
    
    func streamDataDidSend(attachment: Upstream.Attachment, error: Error?) {
    }
    
}
