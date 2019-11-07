//
//  SystemAgent+Directive.swift
//  NuguCore
//
//  Created by yonghoonKwon on 24/05/2019.
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

extension SystemAgent {
    enum DirectiveTypeInfo: CaseIterable {
        case handOffConnection
        case updateState
        case exception
        case noDirectives
    }
}

// MARK: - DirectiveConfigurable

extension SystemAgent.DirectiveTypeInfo: DirectiveTypeInforable {
    var type: String {
        switch self {
        case .handOffConnection: return "System.HandOffConnection"
        case .updateState: return "System.UpdateState"
        case .exception: return "System.Exception"
        case .noDirectives: return "System.NoDirectives"
        }
    }
    
    // CHECK-ME: 확인 필요
    var medium: DirectiveMedium {
        switch self {
        case .handOffConnection: return .none
        case .updateState: return .none
        case .exception: return .none
        case .noDirectives: return .none
        }
    }
    
    // CHECK-ME: 확인 필요
    var isBlocking: Bool {
        switch self {
        case .handOffConnection: return false
        case .updateState: return false
        case .exception: return false
        case .noDirectives: return false
        }
    }
}
