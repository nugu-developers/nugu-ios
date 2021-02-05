//
//  MediaPlayerAgentPlaylist.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/07/27.
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
public struct MediaPlayerAgentPlaylist: Codable {
    /// <#Description#>
    public let name: String?
    /// <#Description#>
    public let number: String
    
    /// The initializer for `MediaPlayerAgentPlaylist`.
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - number: <#number description#>
    init(name: String?, number: String) {
        self.name = name
        self.number = number
    }
}
