//
//  WebOpenExternalApp.swift
//  NuguServiceKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/06/15.
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
public struct WebOpenExternalApp: Decodable {
    public let scheme: String?
    public let appId: String?
    
    enum CodingKeys: String, CodingKey {
        case scheme = "iosScheme"
        case appId = "iosAppId"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        scheme = try values.decodeIfPresent(String.self, forKey: .scheme)
        appId = try values.decodeIfPresent(String.self, forKey: .appId)
    }
}
