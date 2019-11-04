//
//  DisplayAgent+Directive.swift
//  NuguCore
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

import NuguInterface

extension DisplayAgent {
    enum DirectiveTypeInfo: CaseIterable {
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
        case customTemplate
    }
}

// MARK: - DirectiveTypeInforable

extension DisplayAgent.DirectiveTypeInfo: DirectiveTypeInforable {
    var type: String {
        switch self {
        case .fullText1: return "Display.FullText1"
        case .fullText2: return "Display.FullText2"
        case .imageText1: return "Display.ImageText1"
        case .imageText2: return "Display.ImageText2"
        case .imageText3: return "Display.ImageText3"
        case .imageText4: return "Display.ImageText4"
        case .textList1: return "Display.TextList1"
        case .textList2: return "Display.TextList2"
        case .textList3: return "Display.TextList3"
        case .textList4: return "Display.TextList4"
        case .imageList1: return "Display.ImageList1"
        case .imageList2: return "Display.ImageList2"
        case .imageList3: return "Display.ImageList3"
        case .customTemplate: return "Display.CustomTemplate"
        }
    }
    
    var medium: DirectiveMedium {
        return .visual
    }
    
    var isBlocking: Bool {
        return false
    }
}
