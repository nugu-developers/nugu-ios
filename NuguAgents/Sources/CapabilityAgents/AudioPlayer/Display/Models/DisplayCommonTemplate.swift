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

public enum DisplayCommonTemplate {
    public enum Common {
        public struct Image: Decodable {
            public let contentDescription: String?
            public let sources: [Source]
            
            public struct Source: Decodable {
                public let url: String
                public let size: String?
                public let widthPixel: Int?
                public let heightPixel: Int?
            }
        }

        public struct Title: Decodable {
            public let logo: Image?
            public let text: Text
            public let subtext: Text?
            public let subicon: Image?
            public let button: Button?
        }
        
        public struct Background: Decodable {
            public let image: Image?
            public let color: String?
        }
        
        public struct Text: Decodable {
            public let text: String?
            public let color: String?
        }
        
        public struct TextInput: Decodable {
            public let text: String
            public let playServiceId: String?
        }
        
        public struct Button: Decodable {
            public let type: Type?
            public let image: Image?
            public let text: String?
            public let token: String
            public let eventType: EventType?
            public let triggerChild: Bool?
            public let textInput: TextInput?
            public let event: Event?
            public let control: Control?
            public let postback: [String: AnyHashable]?
            public let autoTrigger: AutoTrigger?
            public let closeTemplateAfter: Bool?
            
            public struct AutoTrigger: Decodable {
                public let delayInMilliseconds: Int
                public let showTimer: Bool
            }
            
            public enum `Type`: String, Decodable {
                case text
                case image
            }
            
            private enum CodingKeys: String, CodingKey {
                case type
                case image
                case text
                case token
                case eventType
                case triggerChild
                case textInput
                case event
                case control
                case postback
                case autoTrigger
                case closeTemplateAfter
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                type = try? container.decodeIfPresent(Type.self, forKey: .type)
                image = try? container.decodeIfPresent(Image.self, forKey: .image)
                text = try? container.decodeIfPresent(String.self, forKey: .text)
                token = try container.decode(String.self, forKey: .token)
                eventType = try? container.decodeIfPresent(EventType.self, forKey: .eventType)
                triggerChild = try? container.decodeIfPresent(Bool.self, forKey: .triggerChild)
                textInput = try? container.decodeIfPresent(TextInput.self, forKey: .textInput)
                event = try? container.decodeIfPresent(Event.self, forKey: .event)
                control = try? container.decodeIfPresent(Control.self, forKey: .control)
                // `postback` variable is an optional `[String: AnyHashable]` type which delivers additional information when `Button` object has been clicked.
                // for decoding `[String: AnyHashable]` type, please refer `KeyedDecodingContainer+AnyHashable.swift`
                postback = try? container.decode([String: AnyHashable].self, forKey: .postback)
                autoTrigger = try? container.decodeIfPresent(AutoTrigger.self, forKey: .autoTrigger)
                closeTemplateAfter = try? container.decodeIfPresent(Bool.self, forKey: .closeTemplateAfter)
            }
        }
        
        public enum ImageAlign {
            case left
            case right
            case undefined
        }
        
        public enum Duration {
            case none
            case short
            case mid
            case long
            case longest
        }
        
        public enum BadgeNumberMode {
            case immutability
            case page
        }
        
        public enum EventType {
            case elementSelected
            case textInput
            case event
            case control
        }
        
        public struct Event: Decodable {
            public let type: String
            public let data: [String: AnyHashable]
            
            private enum CodingKeys: String, CodingKey {
                case type
                case data
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                type = try container.decode(String.self, forKey: .type)
                data = try container.decode([String: AnyHashable].self, forKey: .data)
            }
        }
        
        public struct Control: Decodable {
            public let type: `Type`
            public enum `Type` {
                case templatePrevious
                case templateCloseAll
            }
        }
        
        public struct Toggle: Decodable {
            public let style: Style
            public let status: Status
            public let token: String
            
            public enum Style: String, Decodable {
                case image
                case text
            }
            
            public enum Status: String, Decodable {
                case on
                case off
            }
        }
        
        public struct ToggleStyle: Decodable {
            public let text: ToggleStyle.Text?
            public let image: ToggleStyle.Image?
            
            public struct Text: Decodable {
                public let on: DisplayCommonTemplate.Common.Text?
                public let off: DisplayCommonTemplate.Common.Text?
            }
            
            public struct Image: Decodable {
                public let on: DisplayCommonTemplate.Common.Image?
                public let off: DisplayCommonTemplate.Common.Image?
            }
        }
        
        public struct Match: Decodable {
            public let header: Text
            public let body: Text?
            public let footer: Text?
            public let image: Image
            public let score: Text
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

extension DisplayCommonTemplate.Common.EventType: Decodable {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value {
        case "Display.ElementSelected": self = .elementSelected
        case "Text.TextInput": self = .textInput
        case "EVENT": self = .event
        case "CONTROL": self = .control
        default: self = .elementSelected
        }
    }
}

extension DisplayCommonTemplate.Common.Control.`Type`: Decodable {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value {
        case "TEMPLATE_PREVIOUS": self = .templatePrevious
        case "TEMPLATE_CLOSEALL": self = .templateCloseAll
        default: self = .templateCloseAll
        }
    }
}

extension DisplayCommonTemplate.Common.Toggle.Status {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        
        switch value.lowercased() {
        case "on": self = .on
        case "off": self = .off
        default: self = .on
        }
    }
}
