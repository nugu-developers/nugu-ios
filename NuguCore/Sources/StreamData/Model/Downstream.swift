//
//  Downstream.swift
//  NuguCore
//
//  Created by MinChul Lee on 11/22/2019.
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
public enum Downstream {
    /// <#Description#>
    public struct Directive: Codable {
        /// <#Description#>
        public let header: Header
        /// <#Description#>
        public let payload: Data
        
        /// <#Description#>
        /// - Parameters:
        ///   - header: <#header description#>
        ///   - payload: <#payload description#>
        public init(header: Header, payload: Data) {
            self.header = header
            self.payload = payload
        }
    }
    
    /// <#Description#>
    public struct Attachment: Codable {
        /// <#Description#>
        public let header: Header
        /// <#Description#>
        public let seq: Int
        /// <#Description#>
        public let content: Data
        /// <#Description#>
        public let isEnd: Bool
        /// <#Description#>
        public let parentMessageId: String
        /// <#Description#>
        public let mediaType: String
        
        /// <#Description#>
        /// - Parameters:
        ///   - header: <#header description#>
        ///   - seq: <#seq description#>
        ///   - content: <#content description#>
        ///   - isEnd: <#isEnd description#>
        ///   - parentMessageId: <#parentMessageId description#>
        ///   - mediaType: <#mediaType description#>
        public init(header: Header, seq: Int, content: Data, isEnd: Bool, parentMessageId: String, mediaType: String) {
            self.header = header
            self.seq = seq
            self.content = content
            self.isEnd = isEnd
            self.parentMessageId = parentMessageId
            self.mediaType = mediaType
        }
    }
    
    /// <#Description#>
    public struct Header: Codable, Hashable {
        /// <#Description#>
        public let namespace: String
        /// <#Description#>
        public let name: String
        /// <#Description#>
        public let dialogRequestId: String
        /// <#Description#>
        public let messageId: String
        /// <#Description#>
        public let version: String
        
        /// <#Description#>
        /// - Parameters:
        ///   - namespace: <#namespace description#>
        ///   - name: <#name description#>
        ///   - dialogRequestId: <#dialogRequestId description#>
        ///   - messageId: <#messageId description#>
        ///   - version: <#version description#>
        public init(namespace: String, name: String, dialogRequestId: String, messageId: String, version: String) {
            self.namespace = namespace
            self.name = name
            self.dialogRequestId = dialogRequestId
            self.messageId = messageId
            self.version = version
        }
    }
}

// MARK: - Downstream.Header

extension Downstream.Header {
    /// <#Description#>
    public var type: String { "\(namespace).\(name)" }
    
}

// MARK: - Downstream.Header + CustomStringConvertible

/// :nodoc:
extension Downstream.Header: CustomStringConvertible {
    public var description: String {
        return "\(type)(\(messageId))"
    }
}

// MARK: - Downstream.Attachment + CustomStringConvertible

/// :nodoc:
extension Downstream.Attachment: CustomStringConvertible {
    public var description: String {
        return "\(header)), \(seq), \(isEnd)"
    }
}

// MARK: - Downstream.Directive

extension Downstream.Directive {
    /// <#Description#>
    public var payloadDictionary: [String: AnyHashable]? {
        try? JSONSerialization.jsonObject(with: payload, options: []) as? [String: AnyHashable]
    }
}
