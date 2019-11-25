//
//  SoundAgentBeep.swift
//  NuguInterface
//
//  Created by yonghoonKwon on 2019/11/15.
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
public struct SoundAgentBeep {
    /// <#Description#>
    public enum BeepType: String {
        case fail = "FAIL"
    }
    
    /// <#Description#>
    public let playServiceId: String
    
    /// <#Description#>
    public let beepType: BeepType
}

// MARK: - SoundAgentBeep + Decodable

extension SoundAgentBeep: Decodable {
    enum CodingKeys: String, CodingKey {
        case playServiceId
        case beepType = "beepName"
    }
    
    /// <#Description#>
    /// - Parameter decoder: <#decoder description#>
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        playServiceId = try container.decode(String.self, forKey: .playServiceId)
        beepType = try container.decode(BeepType.self, forKey: .beepType)
    }
}

// MARK: - SoundAgentBeep.BeepType + Decodable

extension SoundAgentBeep.BeepType: Decodable {}
