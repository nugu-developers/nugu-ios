//
//  ASRNotifyResult.swift
//  NuguAgents
//
//  Created by MinChul Lee on 13/05/2019.
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

struct ASRNotifyResult {
    let token: String?
    let result: String?
    let state: State
    
    enum State: String, Decodable {
        /// 사용자 발화의 일부분
        case partial = "PARTIAL"
        /// 사용자 발화의 전체 문장
        case complete = "COMPLETE"
        /// 음성 인식 결과 없음
        case none = "NONE"
        /// SOS(Start of Speech)
        case sos = "SOS"
        /// EOS(End of Speech)
        case eos = "EOS"
        /// Wakeup False Acceptance
        case falseAcceptance = "FA"
        /// Error occurred
        case error = "ERROR"
    }
}

// MARK: - ASRNotifyResult: Decodable

extension ASRNotifyResult: Decodable {
    enum CodingKeys: String, CodingKey {
        case token
        case result
        case state
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try? container.decode(String.self, forKey: .token)
        result = try? container.decode(String.self, forKey: .result)
        state = try container.decode(State.self, forKey: .state)
    }
}
