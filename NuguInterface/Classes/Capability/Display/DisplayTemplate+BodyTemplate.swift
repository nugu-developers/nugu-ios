//
//  DisplayTemplate+BodyTemplate.swift
//  NuguInterface
//
//  Created by MinChul Lee on 2019/07/01.
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

public extension DisplayTemplate {
    /// <#Description#>
    struct BodyTemplate: Decodable {
        public let playServiceId: String
        public let token: String
        public let duration: DisplayTemplate.Common.Duration?
        
        /// <#Description#>
        public let title: DisplayTemplate.Common.Title
        /// <#Description#>
        public let background: DisplayTemplate.Common.Background?
        /// <#Description#>
        public let content: Content
        
        /// <#Description#>
        public struct Content: Decodable {
            /// <#Description#>
            public let image: DisplayTemplate.Common.Image?
            /// <#Description#>
            public let imageAlign: DisplayTemplate.Common.ImageAlign?
            /// <#Description#>
            public let header: DisplayTemplate.Common.Text?
            /// <#Description#>
            public let body: DisplayTemplate.Common.Text?
            /// <#Description#>
            public let footer: DisplayTemplate.Common.Text?
        }
    }
}
