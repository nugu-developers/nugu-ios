//
//  MessageSendable.swift
//  NuguInterface
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
public protocol MessageSendable {
    /// <#Description#>
    /// - Parameter upstreamEventMessage: <#upstreamEventMessage description#>
    /// - Parameter delegate: <#delegate description#>
    func send(upstreamEventMessage: UpstreamEventMessage, completion: ((SendMessageStatus) -> Void)?)
    /// <#Description#>
    /// - Parameter upstreamAttachment: <#upstreamAttachment description#>
    /// - Parameter delegate: <#delegate description#>
    func send(upstreamAttachment: UpstreamAttachment, completion: ((SendMessageStatus) -> Void)?)
    /// <#Description#>
    /// - Parameter crashReports: <#crashReports description#>
    func send(crashReports: [CrashReport])
}

public extension MessageSendable {
    /// <#Description#>
    /// - Parameter upstreamEventMessage: <#upstreamEventMessage description#>
    func send(upstreamEventMessage: UpstreamEventMessage) {
        send(upstreamEventMessage: upstreamEventMessage, completion: nil)
    }
    /// <#Description#>
    /// - Parameter upstreamAttachment: <#upstreamAttachment description#>
    func send(upstreamAttachment: UpstreamAttachment) {
        send(upstreamAttachment: upstreamAttachment, completion: nil)
    }
    /// <#Description#>
    /// - Parameter crashReport: <#crashReport description#>
    func send(crashReport: CrashReport) {
        send(crashReports: [crashReport])
    }
    
    /// <#Description#>
    /// - Parameter error: <#error description#>
    /// - Parameter detail: <#detail description#>
    func sendCrashReport(error: Error, detail: String = "") {
        let crashReport = CrashReport(level: .error, message: error.localizedDescription, detail: detail)
        send(crashReport: crashReport)
    }
}
