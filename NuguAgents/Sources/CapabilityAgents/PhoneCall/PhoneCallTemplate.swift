//
//  PhoneCallTemplate.swift
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
public struct PhoneCallTemplate: Encodable {
    /// <#Description#>
    public let intent: PhoneCallIntent?
    /// <#Description#>
    public let callType: PhoneCallType?
    /// <#Description#>
    public let recipientIntended: PhoneCallRecipient?
    /// <#Description#>
    public let candidates: [PhoneCallPerson]?
    
    /// <#Description#>
    /// - Parameters:
    ///   - intent: <#intent description#>
    ///   - callType: <#callType description#>
    ///   - recipientIntended: <#recipientIntended description#>
    ///   - candidates: <#candidates description#>
    public init(
        intent: PhoneCallIntent?,
        callType: PhoneCallType?,
        recipientIntended: PhoneCallRecipient?,
        candidates: [PhoneCallPerson]?
    ) {
        self.intent = intent
        self.callType = callType
        self.recipientIntended = recipientIntended
        self.candidates = candidates
    }
}
