//
//  PhoneCallAgentDelegate.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/05/12.
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

/// <#Description#>
public protocol PhoneCallAgentDelegate: class {
    /// <#Description#>
    func phoneCallAgentRequestContext() -> PhoneCallContext
    
    /// <#Description#>
    /// - Parameters:
    ///   - item: <#item description#>
    ///   - dialogRequestId: <#dialogRequestId description#>
    func phoneCallAgentDidReceiveSendCandidates(item: PhoneCallCandidatesItem, dialogRequestId: String)
    
    /// <#Description#>
    /// - Parameters:
    ///   - callType: <#callType description#>
    ///   - recipient: <#recipient description#>
    ///   - dialogRequestId: <#dialogRequestId description#>
    func phoneCallAgentDidReceiveMakeCall(callType: PhoneCallType, recipient: PhoneCallPerson, dialogRequestId: String) -> PhoneCallErrorCode?
}
