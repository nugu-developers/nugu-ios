//
//  NuguClientDelegate.swift
//  NuguClientKit
//
//  Created by childc on 2020/01/13.
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

public protocol NuguClientDelegate: class {
    // audio session related
    func nuguClientWillRequireAudioSession() -> Bool
    func nuguClientDidReleaseAudioSession()
    
    // input source related
    func nuguClientWillOpenInputSource()
    func nuguClientDidOpenInputSource()
    func nuguClientDidCloseInputSource()
    func nuguClientDidErrorDuringInputSourceSetup(_ error: Error)

    // nugu server related
    func nuguClientDidReceive(direcive: Downstream.Directive)
    func nuguClientDidReceive(attachment: Downstream.Attachment)
    func nuguClientDidSend(event: Upstream.Event, error: Error?)
    func nuguClientDidSend(attachment: Upstream.Attachment, error: Error?)
    
    // authorization related
    func nuguClientRequestAccessToken() -> String?
}

// MARK: - Optional

public extension NuguClientDelegate {
    // audio session related
    func nuguClientDidReleaseAudioSession() {}
    
    // input source related
    func nuguClientWillOpenInputSource() {}
    func nuguClientDidOpenInputSource() {}
    func nuguClientDidCloseInputSource() {}
    
    // nugu server related
    func nuguClientDidReceive(direcive: Downstream.Directive) {}
    func nuguClientDidReceive(attachment: Downstream.Attachment) {}
    func nuguClientDidSend(event: Upstream.Event, error: Error?) {}
    func nuguClientDidSend(attachment: Upstream.Attachment, error: Error?) {}
}
