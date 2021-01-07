//
//  StreamDataDelegate.swift
//  NuguCore
//
//  Created by MinChul Lee on 2020/03/18.
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

/// A protocol for notifying events about stream data
public protocol StreamDataDelegate: class {
    /// Invoked after receiving the directive.
    /// - Parameter direcive: The received directive.
    func streamDataDidReceive(direcive: Downstream.Directive)
    
    /// Invoked after receiving the attachment.
    /// - Parameter attachment: The received attachment.
    func streamDataDidReceive(attachment: Downstream.Attachment)
    
    /// Invoked before sending the event.
    /// - Parameter event: The event to send.
    func streamDataWillSend(event: Upstream.Event)
    
    /// Invoked after sending the event.
    /// - Parameters:
    ///   - event: The sent event.
    ///   - error: An error object that indicates why the request failed, or nil if the request was successful.
    func streamDataDidSend(event: Upstream.Event, error: Error?)
    
    /// Invoked after sending the attachment.
    /// - Parameters:
    ///   - attachment: The sent attachment.
    ///   - error: An error object that indicates why the request failed, or nil if the request was successful.
    func streamDataDidSend(attachment: Upstream.Attachment, error: Error?)
}
