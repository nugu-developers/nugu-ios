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

/// <#Description#>
public typealias DirectiveHandleInfos = [String: DirectiveHandleInfo]
/// <#Description#>
public typealias PrefetchDirective = (_ directive: Downstream.Directive) throws -> Void
/// <#Description#>
public typealias HandleDirective = (_ directive: Downstream.Directive, _ completion: @escaping (DirectiveHandleResult) -> Void) -> Void
/// <#Description#>
public typealias CancelDirective = (_ directive: Downstream.Directive) -> Void
/// <#Description#>
public typealias HandleAttachment = (_ attachment: Downstream.Attachment) -> Void

/// <#Description#>
public struct DirectiveHandleInfo: Hashable {
    /// <#Description#>
    public let namespace: String
    /// <#Description#>
    public let name: String
    /// <#Description#>
    public let blockingPolicy: BlockingPolicy
    /// <#Description#>
    public let preFetch: PrefetchDirective?
    /// <#Description#>
    public let cancelDirective: CancelDirective?
    /// <#Description#>
    public let directiveHandler: HandleDirective
    /// <#Description#>
    public let attachmentHandler: HandleAttachment?
    
    /// <#Description#>
    public var type: String {
        return "\(namespace).\(name)"
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - namespace: <#namespace description#>
    ///   - name: <#name description#>
    ///   - blockingPolicy: <#blockingPolicy description#>
    ///   - preFetch: <#preFetch description#>
    ///   - directiveHandler: <#directiveHandler description#>
    ///   - cancelDirective: <#cancelDirective description#>
    ///   - attachmentHandler: <#attachmentHandler description#>
    public init(
        namespace: String,
        name: String,
        blockingPolicy: BlockingPolicy,
        preFetch: (() -> PrefetchDirective)? = nil,
        cancelDirective: (() -> CancelDirective)? = nil,
        directiveHandler: () -> HandleDirective,
        attachmentHandler: (() -> HandleAttachment)? = nil
    ) {
        self.namespace = namespace
        self.name = name
        self.blockingPolicy = blockingPolicy
        self.preFetch = preFetch?()
        self.cancelDirective = cancelDirective?()
        self.directiveHandler = directiveHandler()
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

// MARK: - Array + DirectiveTypeInforable

public extension Array where Element == DirectiveHandleInfo {
    var asDictionary: DirectiveHandleInfos {
        return self.reduce(into: [String: DirectiveHandleInfo]()) { result, directiveTypeInfo in
            result[directiveTypeInfo.type] = directiveTypeInfo
        }
    }
}
