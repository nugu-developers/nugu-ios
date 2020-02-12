//
//  DisplayAgent+Directive.swift
//  NuguAgents
//
//  Created by MinChul Lee on 16/05/2019.
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

import NuguCore

// MARK: - CapabilityDirectiveAgentable

extension DisplayAgent {
    public enum DirectiveTypeInfo: CaseIterable {
        case close
        case fullText1
        case fullText2
        case imageText1
        case imageText2
        case imageText3
        case imageText4
        case textList1
        case textList2
        case textList3
        case textList4
        case imageList1
        case imageList2
        case imageList3
        case weather1
        case weather2
        case weather3
        case weather4
        case weather5
        case fullImage
        case score1
        case score2
        case searchList1
        case searchList2
        case customTemplate
    }
}

// MARK: - DirectiveTypeInforable

extension DisplayAgent.DirectiveTypeInfo: DirectiveTypeInforable {
    public var namespace: String { "Display" }
    
    public var name: String {
        switch self {
        case .close: return "Close"
        case .fullText1: return "FullText1"
        case .fullText2: return "FullText2"
        case .imageText1: return "ImageText1"
        case .imageText2: return "ImageText2"
        case .imageText3: return "ImageText3"
        case .imageText4: return "ImageText4"
        case .textList1: return "TextList1"
        case .textList2: return "TextList2"
        case .textList3: return "TextList3"
        case .textList4: return "TextList4"
        case .imageList1: return "ImageList1"
        case .imageList2: return "ImageList2"
        case .imageList3: return "ImageList3"
        case .weather1: return "Weather1"
        case .weather2: return "Weather2"
        case .weather3: return "Weather3"
        case .weather4: return "Weather4"
        case .weather5: return "Weather5"
        case .fullImage: return "FullImage"
        case .score1: return "Score1"
        case .score2: return "Score2"
        case .searchList1: return "SearchList1"
        case .searchList2: return "SearchList2"
        case .customTemplate: return "CustomTemplate"
        }
    }
    
    public var medium: DirectiveMedium {
        return .visual
    }
    
    public var isBlocking: Bool {
        return false
    }
}
