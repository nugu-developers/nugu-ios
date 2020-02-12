//
//  SystemAgent+Directive.swift
//  NuguAgents
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

import NuguCore

// MARK: - CapabilityDirectiveAgentable

extension SystemAgent {
    public enum DirectiveTypeInfo: CaseIterable {
        case handoffConnection
        case updateState
        case exception
        case noDirectives
    }
}

// MARK: - DirectiveConfigurable

extension SystemAgent.DirectiveTypeInfo: DirectiveTypeInforable {
    public var namespace: String { "System" }
    
    public var name: String {
        switch self {
        case .handoffConnection: return "HandoffConnection"
        case .updateState: return "UpdateState"
        case .exception: return "Exception"
        case .noDirectives: return "NoDirectives"
        }
    }
    
    // CHECK-ME: 확인 필요
    public var medium: DirectiveMedium {
        switch self {
        case .handoffConnection: return .none
        case .updateState: return .none
        case .exception: return .none
        case .noDirectives: return .none
        }
    }
    
    // CHECK-ME: 확인 필요
    public var isBlocking: Bool {
        switch self {
        case .handoffConnection: return false
        case .updateState: return false
        case .exception: return false
        case .noDirectives: return false
        }
    }
}
