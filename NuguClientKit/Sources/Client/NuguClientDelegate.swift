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
import NuguAgents

/// <#Description#>
public protocol NuguClientDelegate: AnyObject {
    // audio session related
    /// Notify that  nugu client should update audio session
    /// - Parameter requestingFocus: whether updating AudioSession is for requesting focus or just updating without requesting focus
    @discardableResult func nuguClientShouldUpdateAudioSession(requestingFocus: Bool) -> Bool
    
    /// Notify that nugu client won't play sound anymore.
    func nuguClientDidReleaseAudioSession()
    
    /// Notify that  nugu client speech-related state has been changed
    func nuguClientDidChangeSpeechState(_ state: SpeechRecognizerAggregatorState)
    
    // nugu server related
    /// Notify that nugu client received directive
    /// - Parameter direcive: Response from server
    func nuguClientDidReceive(direcive: Downstream.Directive)
    
    /// Notify that nugu client received some data which is attached the directive
    /// - Parameter attachment: Data to be processed in the response
    func nuguClientDidReceive(attachment: Downstream.Attachment)
    
    /// Notify that nugu client will send a event
    /// - Parameter event: Request
    func nuguClientWillSend(event: Upstream.Event)
    
    /// Notify that the request is sent
    /// - Parameters:
    ///   - event: Request
    ///   - error: Error during sending an event description
    func nuguClientDidSend(event: Upstream.Event, error: Error?)
    
    /// Notify that the data to be processed is sent
    /// - Parameters:
    ///   - attachment: Data to be processed on server
    ///   - error: Error during sending an event data
    func nuguClientDidSend(attachment: Upstream.Attachment, error: Error?)
    
    // authorization related
    
    /// Provides an access token from cache(ex> `UserDefault`).
    ///
    /// - returns: The current authorization token.
    func nuguClientRequestAccessToken() -> String?
    
    func nuguClientServerInitiatedDirectiveRecevierStateDidChange(_ state: ServerSideEventReceiverState)
}

// MARK: - Optional

public extension NuguClientDelegate {
    // audio session related
    func nuguClientDidReleaseAudioSession() {}
    
    // nugu server related
    func nuguClientDidReceive(direcive: Downstream.Directive) {}
    func nuguClientDidReceive(attachment: Downstream.Attachment) {}
    func nuguClientDidSend(event: Upstream.Event, error: Error?) {}
    func nuguClientDidSend(attachment: Upstream.Attachment, error: Error?) {}
    func nuguClientServerInitiatedDirectiveRecevierStateDidChange(_ state: ServerSideEventReceiverState) {}
}
