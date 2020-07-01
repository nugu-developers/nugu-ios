//
//  PhoneCallCandidatesItem.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/07/01.
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

public struct PhoneCallCandidatesItem: Decodable {
    
    public let playServiceId: String
    public let intent: PhoneCallIntent
    public let callType: PhoneCallType?
    public let recipient: PhoneCallRecipient?
    public let candidates: [PhoneCallPerson]?
    
    public init(playServiceId: String, intent: PhoneCallIntent, callType: PhoneCallType?, recipient: PhoneCallRecipient, candidates: [PhoneCallPerson]?) {
        self.playServiceId = playServiceId
        self.intent = intent
        self.callType = callType
        self.recipient = recipient
        self.candidates = candidates
    }
}
