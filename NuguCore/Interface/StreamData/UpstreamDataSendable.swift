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

/// <#Description#>
public protocol UpstreamDataSendable {
    /**
     Send a event.
     */
    func sendEvent(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)?)

    /**
     Send a event and keep the stream for future attachment
     */
    func sendStream(_ event: Upstream.Event, completion: ((StreamDataState) -> Void)?)
    
    /**
     Send a attachment using the stream set before.
     
     Every event and attachment have `DialogRequestId`.
     This method finds the suitable stream using that id
     */
    func sendStream(_ attachment: Upstream.Attachment, completion: ((StreamDataState) -> Void)?)
}

public extension UpstreamDataSendable {
    func sendEvent(_ event: Upstream.Event) {
        sendEvent(event, completion: nil)
    }
    
    func sendStream(_ attachment: Upstream.Attachment) {
        sendStream(attachment, completion: nil)
    }
}
