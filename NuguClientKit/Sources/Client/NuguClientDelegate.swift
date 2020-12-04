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

/// <#Description#>
public protocol NuguClientDelegate: class {
    // audio session related
    /// <#Description#>
    func nuguClientWillRequireAudioSession() -> Bool
    
    /// <#Description#>
    func nuguClientDidReleaseAudioSession()
    
    // nugu server related
    /// <#Description#>
    /// - Parameter direcive: <#direcive description#>
    func nuguClientDidReceive(direcive: Downstream.Directive)
    
    /// <#Description#>
    /// - Parameter attachment: <#attachment description#>
    func nuguClientDidReceive(attachment: Downstream.Attachment)
    
    /// <#Description#>
    /// - Parameter event: <#event description#>
    func nuguClientWillSend(event: Upstream.Event)
    
    /// <#Description#>
    /// - Parameters:
    ///   - event: <#event description#>
    ///   - error: <#error description#>
    func nuguClientDidSend(event: Upstream.Event, error: Error?)
    
    /// <#Description#>
    /// - Parameters:
    ///   - attachment: <#attachment description#>
    ///   - error: <#error description#>
    func nuguClientDidSend(attachment: Upstream.Attachment, error: Error?)
    
    // authorization related
    
    /// Provides an access token from cache(ex> `UserDefault`).
    ///
    /// - returns: The current authorization token.
    func nuguClientRequestAccessToken() -> String?
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
}
