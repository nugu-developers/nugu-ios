//
//  Downstream.swift
//  NuguInterface
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

public protocol DownstreamMessageable {
    var header: Downstream.Header { get }
}

public struct Downstream {
    public struct Directive: DownstreamMessageable, Decodable {
        public let header: Header
        public let payload: String
        
        public init(header: Header, payload: String) {
            self.header = header
            self.payload = payload
        }
    }
    
    public struct Attachment: DownstreamMessageable, Decodable {
        public let header: Header
        public let seq: Int
        public let content: Data
        public let isEnd: Bool
        public let parentMessageId: String
        public let mediaType: String
        
        public init(header: Header, seq: Int, content: Data, isEnd: Bool, parentMessageId: String, mediaType: String) {
            self.header = header
            self.seq = seq
            self.content = content
            self.isEnd = isEnd
            self.parentMessageId = parentMessageId
            self.mediaType = mediaType
        }
    }
    
    public struct Header: Decodable {
        public let namespace: String
        public let name: String
        public let dialogRequestId: String
        public let referrerDialogRequestId: String?
        public let messageId: String
        public let version: String
        
        public init(namespace: String, name: String, dialogRequestId: String, messageId: String, version: String, referrerDialogRequestId: String? = nil) {
            self.namespace = namespace
            self.name = name
            self.dialogRequestId = dialogRequestId
            self.messageId = messageId
            self.version = version
            self.referrerDialogRequestId = referrerDialogRequestId
        }
    }
}

// MARK: - Downstream.Directive

extension Downstream.Directive {
    /// <#Description#>
    /// - Parameter Type: <#Type description#>
    public func typeInfo<T: CaseIterable & DirectiveTypeInforable>(for configurationType: T.Type) -> T? {
        return configurationType.allCases.first { (configuration) -> Bool in
            return configuration.type == header.type
        }
    }
}

// MARK: - Downstream.Header

extension Downstream.Header {
    public var type: String { "\(namespace).\(name)" }
}
