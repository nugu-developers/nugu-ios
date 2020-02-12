//
//  DirectiveTypeInfos.swift
//  NuguCore
//
//  Created by MinChul Lee on 10/04/2019.
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

/// [String: DirectiveTypeInforable]
public typealias DirectiveTypeInfos = [String: DirectiveTypeInforable]

/// <#Description#>
public protocol DirectiveTypeInforable {
    /// <#Description#>
    var namespace: String { get }
    /// <#Description#>
    var name: String { get }
    /// <#Description#>
    var type: String { get }
    /// <#Description#>
    var medium: DirectiveMedium { get }
    /// <#Description#>
    var isBlocking: Bool { get }
}

public extension DirectiveTypeInforable {
    var type: String { "\(namespace).\(name)" }
}

/// <#Description#>
public enum DirectiveMedium: CaseIterable {
    /// <#Description#>
    case none
    /// <#Description#>
    case audio
    /// <#Description#>
    case visual
}

// MARK: - Array + DirectiveTypeInforable

public extension Array where Element == DirectiveTypeInforable {
    /// <#Description#>
    /// - Parameter element: <#element description#>
    @discardableResult mutating func remove(element: Element) -> Bool {
        if let index = firstIndex(where: { comparedElement -> Bool in
            guard
                comparedElement.type == element.type,
                comparedElement.medium == element.medium,
                comparedElement.isBlocking == element.isBlocking else {
                    return false
            }
            
            return true
        }) {
            remove(at: index)
            return true
        }

        return false
    }
    
    /// <#Description#>
    /// - Parameter medium: <#medium description#>
    func isBlock(medium: DirectiveMedium) -> Bool {
        return contains(where: { typeInfo -> Bool in
            return typeInfo.isBlocking && typeInfo.medium == medium
        })
    }
}

// MARK: - CaseIterable + DirectiveTypeInforable

public extension CaseIterable where Self: DirectiveTypeInforable {
    /// <#Description#>
    static var allDictionaryCases: DirectiveTypeInfos {
        return Self.allCases.reduce(
            into: [String: DirectiveTypeInforable]()
        ) { result, configuration in
            result[configuration.type] = configuration
        }
    }
}
