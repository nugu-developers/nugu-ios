//
//  UpstreamDataSendable.swift
//  NuguCore
//
//  Created by MinChul Lee on 19/04/2019.
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

/// A protocol for sending `Upstream` data to the server.
public protocol UpstreamDataSendable: AnyObject {
    /// Sends an event.
    ///
    /// - Parameters:
    ///   - event: The event to send.
    ///   - completion: The completion handler to call when the request is complete.
    func sendEvent(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)?)
    
    /// Sends an event and keep the stream for future attachment
    ///
    /// - Parameters:
    ///   - event: The event to send.
    ///   - completion: The completion handler to call when the request is complete.
    func sendStream(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)?)
    
    /// Sends an attachment using the stream set before.
    ///
    /// Every event and attachment have `DialogRequestId` and this method finds the suitable stream using that id.
    ///
    /// - Parameters:
    ///   - attachment: The attachmen to send.
    ///   - completion: The completion handler to call when the request is complete.
    func sendStream(_ attachment: Upstream.Attachment, completion: ((StreamDataState) -> Void)?)
    
    /// Cancels an event.
    ///
    /// - Parameter dialogRequestId: The event's `dialogRequestId` to cancel.
    func cancelEvent(dialogRequestId: String)
}

public extension UpstreamDataSendable {
    /// Sends an event.
    ///
    /// - Parameters:
    ///   - event: The event to send.
    func sendEvent(_ event: Upstream.Event) {
        sendEvent(event, completion: nil)
    }
    
    /// Sends an attachment using the stream set before.
    ///
    /// Every event and attachment have `DialogRequestId` and this method finds the suitable stream using that id.
    ///
    /// - Parameters:
    ///   - attachment: The attachmen to send.
    func sendStream(_ attachment: Upstream.Attachment) {
        sendStream(attachment, completion: nil)
    }
}
