//
//  DirectiveHandleInfo.swift
//  NuguCore
//
//  Created by childc on 15/02/2020.
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

public typealias DirectiveHandleInfos = [String: DirectiveHandleInfo]
public typealias HandleDirective = (_ directive: Downstream.Directive, _ completion: @escaping (Result<Void, Error>) -> Void) -> Void
public typealias HandleAttachment = (_ attachment: Downstream.Attachment) -> Void

public struct DirectiveHandleInfo: Hashable {
    public let namespace: String
    public let name: String
    public let medium: DirectiveMedium
    public let isBlocking: Bool
    public let directiveHandler: HandleDirective
    public let preFetch: HandleDirective
    public let attachmentHandler: HandleAttachment?
    
    public var type: String {
        return "\(namespace).\(name)"
    }
    
    public init(
        namespace: String,
        name: String,
        medium: DirectiveMedium,
        isBlocking: Bool,
        preFetch: (() -> HandleDirective) = { { $1(.success(())) } },
        directiveHandler: () -> HandleDirective,
        attachmentHandler: (() -> HandleAttachment)? = nil
    ) {
        self.namespace = namespace
        self.name = name
        self.medium = medium
        self.isBlocking = isBlocking
        self.directiveHandler = directiveHandler()
        self.preFetch = preFetch()
        self.attachmentHandler = attachmentHandler?()
    }
    
    // hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(namespace.hashValue)
        hasher.combine(name.hashValue)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

public enum DirectiveMedium: CaseIterable {
    case none
    case audio
    case visual
}

// MARK: - Array + DirectiveTypeInforable

public extension Array where Element == DirectiveHandleInfo {
    /// <#Description#>
    /// - Parameter element: <#element description#>
    @discardableResult mutating func remove(element: Element) -> Bool {
        guard let index = firstIndex(where: { $0.type == element.type
            && $0.medium == element.medium
            && $0.isBlocking == element.isBlocking }) else {
                return false
        }
        
        remove(at: index)
        return true
    }
    
    func isBlock(medium: DirectiveMedium) -> Bool {
        return contains { $0.isBlocking && $0.medium == medium }
    }
    
    var asDictionary: DirectiveHandleInfos {
        return self.reduce(into: [String: DirectiveHandleInfo]()) { result, directiveTypeInfo in
            result[directiveTypeInfo.type] = directiveTypeInfo
        }
    }
}
