//
//  NuguCoreConfiguration.swift
//  NuguCore
//
//  Created by MinChul Lee on 16/04/2019.
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
public struct NuguConfiguration: Decodable {
    /// <#Description#>
    var asrResponseTimeout: DispatchTimeInterval = .milliseconds(10000)
    /// <#Description#>
    var asrEncoding: String = "PARTIAL" // "PARTIAL" or "COMPLETE"
    // TODO never 로 설정할 수 있는 방법 제공.
    /// <#Description#>
    var audioPlayerPauseTimeout: DispatchTimeInterval = .milliseconds(600000)
    /// <#Description#>
    var registryAddress: String = "https://reg-http.sktnugu.com:443/v1/"

    enum CodingKeys: String, CodingKey {
        case asrResponseTimeout = "AutomatedSpeechRecognitionResponseTimeout"
        case asrEncoding = "AutomatedSpeechRecognitionEncoding"
        case audioPlayerPauseTimeout = "AudioPlayerPauseTimeout"
        case nuguServerType = "NuguServerType"
        case registryAddress = "RegisteryServerBaseUrl"
    }

    init() {}
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let value = try values.decodeIfPresent(Int.self, forKey: .asrResponseTimeout) {
            asrResponseTimeout = .milliseconds(value)
        }
        if let value = try values.decodeIfPresent(String.self, forKey: .asrEncoding) {
            self.asrEncoding = value
        }
        if let value = try values.decodeIfPresent(Int.self, forKey: .audioPlayerPauseTimeout) {
            audioPlayerPauseTimeout = .milliseconds(value)
        }
        if let value = try values.decodeIfPresent(String.self, forKey: .registryAddress) {
            registryAddress = value
        }
    }
}
