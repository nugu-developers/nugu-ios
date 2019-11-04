//
//  DisplayTemplate+Common.swift
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
    struct Common {
        /// <#Description#>
        public struct Image: Decodable {
            /// <#Description#>
            public let contentDescription: String?
            /// <#Description#>
            public let sources: [Source]
            
            /// <#Description#>
            public struct Source: Decodable {
                /// <#Description#>
                public let url: String
                /// <#Description#>
                public let size: String?
                /// <#Description#>
                public let widthPixel: Int?
                /// <#Description#>
                public let heightPixel: Int?
            }
        }
        
        /// <#Description#>
        public struct Title: Decodable {
            /// <#Description#>
            public let logo: Image
            /// <#Description#>
            public let text: Text
            public let subtext: Text?
            public let subicon: Image?
            public let button: Button?
        }
        
        /// <#Description#>
        public struct Background: Decodable {
            /// <#Description#>
            public let image: Image?
            /// <#Description#>
            public let color: String?
        }
        
        /// <#Description#>
        public struct Text: Decodable {
            /// <#Description#>
            public let text: String
            /// <#Description#>
            public let color: String?
        }
        
        public struct Button: Decodable {
            public let text: String
            public let token: String
        }
        
        /// <#Description#>
        public enum ImageAlign {
            /// <#Description#>
            case left
            /// <#Description#>
            case right
            /// <#Description#>
            case undefined
        }
        
        /// <#Description#>
        public enum Duration {
            /// <#Description#>
            case short
            /// <#Description#>
            case mid
            /// <#Description#>
            case long
        }
        
        public struct BadgeNumberStyle: Decodable {
            public let background: String
            public let color: String
            public let borderRadius: String
            
            enum CodingKeys: String, CodingKey {
                case background
                case color
                case borderRadius = "border-radius"
            }
        }
    }
}

extension DisplayTemplate.Common.ImageAlign: Decodable {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value {
        case "LEFT": self = .left
        case "RIGHT": self = .right
        default: self = .undefined
        }
    }
}

extension DisplayTemplate.Common.Duration: Decodable {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value {
        case "SHORT": self = .short
        case "MID": self = .mid
        case "LONG": self = .long
        default: self = .short
        }
    }
}

public extension DisplayTemplate.Common.Duration {
    var time: DispatchTimeInterval {
        switch self {
        case .short: return .seconds(7)
        case .mid: return .seconds(15)
        case .long: return .seconds(30)
        }
    }
}
