//
//  DisplayCommonTemplate.swift
//  NuguUIKit
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
            let text: String?
            let color: String?
        }
        
        struct TextInput: Decodable {
            let text: String
            let playServiceId: String?
        }
        
        struct Button: Decodable {
            let type: Type?
            let image: Image?
            let text: String?
            let token: String
            let eventType: EventType?
            let textInput: TextInput?
            let postback: [String: AnyHashable]?
            let autoTrigger: AutoTrigger?
            let closeTemplateAfter: Bool?
            
            struct AutoTrigger: Decodable {
                let delayInMilliseconds: Int
                let showTimer: Bool
            }
            
            enum `Type`: String, Decodable {
                case text
                case image
            }
            
            enum CodingKeys: String, CodingKey {
                case type
                case image
                case text
                case token
                case eventType
                case textInput
                case postback
                case autoTrigger
                case closeTemplateAfter
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                type = try? container.decodeIfPresent(Type.self, forKey: .type)
                image = try? container.decodeIfPresent(Image.self, forKey: .image)
                text = try? container.decodeIfPresent(String.self, forKey: .text)
                token = try container.decode(String.self, forKey: .token)
                eventType = try? container.decodeIfPresent(EventType.self, forKey: .eventType)
                textInput = try? container.decodeIfPresent(TextInput.self, forKey: .textInput)
                // `postback` variable is an optional `[String: AnyHashable]` type which delivers additional information when `Button` object has been clicked.
                // for decoding `[String: AnyHashable]` type, please refer `KeyedDecodingContainer+AnyHashable.swift`
                postback = try? container.decode([String: AnyHashable].self, forKey: .postback)
                autoTrigger = try? container.decodeIfPresent(AutoTrigger.self, forKey: .autoTrigger)
                closeTemplateAfter = try? container.decodeIfPresent(Bool.self, forKey: .closeTemplateAfter)
            }
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
        
        enum EventType {
            case elementSelected
            case textInput
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
        
        struct ToggleStyle: Decodable {
            let text: ToggleStyle.Text?
            let image: ToggleStyle.Image?
            
            struct Text: Decodable {
                let on: DisplayCommonTemplate.Common.Text?
                let off: DisplayCommonTemplate.Common.Text?
            }
            
            struct Image: Decodable {
                let on: DisplayCommonTemplate.Common.Image?
                let off: DisplayCommonTemplate.Common.Image?
            }
        }
        
        struct Match: Decodable {
            let header: Text
            let body: Text?
            let footer: Text?
            let image: Image
            let score: Text
        }
    }
}

extension DisplayCommonTemplate.Common.ImageAlign: Decodable {
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value {
        case "LEFT": self = .left
        case "RIGHT": self = .right
        default: self = .undefined
        }
    }
}

extension DisplayCommonTemplate.Common.Duration: Decodable {
    init(from decoder: Decoder) throws {
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
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value {
        case "IMMUTABILITY": self = .immutability
        case "PAGE": self = .page
        default: self = .immutability
        }
    }
}

extension DisplayCommonTemplate.Common.EventType: Decodable {
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value {
        case "Display.ElementSelected": self = .elementSelected
        case "Text.TextInput": self = .textInput
        default: self = .elementSelected
        }
    }
}

extension DisplayCommonTemplate.Common.Toggle.Status {
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value.lowercased() {
        case "on": self = .on
        case "off": self = .off
        default: self = .on
        }
    }
}
