//
//  InteractionControlManageable.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/08/07.
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

import NuguUtils

/// <#Description#>
public protocol InteractionControlManageable: class, TypedNotifyable {
    /// <#Description#>
    /// - Parameters:
    ///   - mode: <#mode description#>
    ///   - category: <#category description#>
    func start(mode: InteractionControl.Mode, category: CapabilityAgentCategory)
    
    /// <#Description#>
    /// - Parameters:
    ///   - mode: <#mode description#>
    ///   - category: <#category description#>
    func finish(mode: InteractionControl.Mode, category: CapabilityAgentCategory)
}
