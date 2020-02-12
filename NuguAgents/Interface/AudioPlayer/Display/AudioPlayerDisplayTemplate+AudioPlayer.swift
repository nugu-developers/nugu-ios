//
//  AudioPlayerDisplayTemplate+AudioPlayer.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2019/07/03.
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

public extension AudioPlayerDisplayTemplate {
    /// <#Description#>
    struct AudioPlayer: Decodable {
        /// <#Description#>
        public let template: Template
        
        /// <#Description#>
        public struct Template: Decodable {
            /// <#Description#>
            public let type: String
            /// <#Description#>
            public let title: Title
            /// <#Description#>
            public let content: Content
            
            /// <#Description#>
            public struct Title: Decodable {
                /// <#Description#>
                public let iconUrl: String?
                /// <#Description#>
                public let text: String
            }
            
            /// <#Description#>
            public struct Content: Decodable {
                /// <#Description#>
                public let title: String
                /// <#Description#>
                public let subtitle: String?
                /// <#Description#>
                public let subtitle1: String?
                /// <#Description#>
                public let subtitle2: String?
                /// <#Description#>
                public let imageUrl: String?
                /// <#Description#>
                public let durationSec: Int?
                /// <#Description#>
                public let backgroundColor: String?
                /// <#Description#>
                public let backgroundImageUrl: String?
            }
        }
    }
}
