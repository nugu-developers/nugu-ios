//
//  DisplayCommonTemplate.swift
//  SampleApp
//
//  Created by jin kim on 2019/11/06.
//  Copyright © 2019 SK Telecom Co., Ltd. All rights reserved.
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

struct DisplayCommonTemplate: Decodable {
    struct Common {
        struct Image: Decodable {
            let contentDescription: String?
            let sources: [Source]
            
            struct Source: Decodable {
                let url: String
                let size: String?
                let widthPixel: Int?
                let heightPixel: Int?
            }
        }

        struct Title: Decodable {
            let logo: Image?
            let text: Text
            let subtext: Text?
            let subicon: Image?
            let button: Button?
        }
        
        struct Background: Decodable {
            let image: Image?
            let color: String?
        }
        
        struct Text: Decodable {
            let text: String
            let color: String?
        }
        
        struct Button: Decodable {
            let text: String
            let token: String
        }
        
        enum ImageAlign {
            case left
            case right
            case undefined
        }
        
        enum Duration {
            case none
            case short
            case mid
            case long
            case longest
        }
        
        enum BadgeNumberMode {
            case immutability
            case page
        }
        
        struct Toggle: Decodable {
            let style: Style
            let status: Status
            let token: String
            
            enum Style: String, Decodable {
                case image
                case text
            }
            
            enum Status: String, Decodable {
                case on
                case off
            }
        }
    }
}

extension DisplayCommonTemplate.Common.ImageAlign: Decodable {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value {
        case "LEFT": self = .left
        case "RIGHT": self = .right
        default: self = .undefined
        }
    }
}

extension DisplayCommonTemplate.Common.Duration: Decodable {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value {
        case "NONE": self = .none
        case "SHORT": self = .short
        case "MID": self = .mid
        case "LONG": self = .long
        case "LONGEST": self = .longest
        default: self = .short
        }
    }
}

extension DisplayCommonTemplate.Common.BadgeNumberMode: Decodable {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value {
        case "IMMUTABILITY": self = .immutability
        case "PAGE": self = .page
        default: self = .immutability
        }
    }
}
