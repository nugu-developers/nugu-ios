//
//  DirectiveProtocol.swift
//  NuguInterface
//
//  Created by MinChul Lee on 14/05/2019.
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

/// <#Description#>
public protocol DirectiveProtocol {
    /// <#Description#>
    var payload: String { get }
    /// <#Description#>
    var header: MessageHeaderProtocol { get }
}

// MARK: - DirectiveProtocol + DirectiveTypeInforable

public extension DirectiveProtocol {
    /// <#Description#>
    /// - Parameter Type: <#Type description#>
    func typeInfo<T: CaseIterable & DirectiveTypeInforable>(for configurationType: T.Type) -> T? {
        return configurationType.allCases.first { (configuration) -> Bool in
            return configuration.type == header.type
        }
    }
}
