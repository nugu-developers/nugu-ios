//
//  Upstream.swift
//  NuguCore
//
//  Created by MinChul Lee on 2020/03/18.
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
public enum Upstream {
    
    // MARK: Event
    
    /// <#Description#>
    public struct Event {
        /// <#Description#>
        public struct Header: Encodable {
            /// <#Description#>
            public let namespace: String
            /// <#Description#>
            public let name: String
            /// <#Description#>
            public let version: String
            /// <#Description#>
            public let dialogRequestId: String
            /// <#Description#>
            public let messageId: String
            /// <#Description#>
            public let referrerDialogRequestId: String?
            
            /// <#Description#>
            /// - Parameters:
            ///   - namespace: <#namespace description#>
            ///   - name: <#name description#>
            ///   - version: <#version description#>
            ///   - dialogRequestId: <#dialogRequestId description#>
            ///   - messageId: <#messageId description#>
            ///   - referrerDialogRequestId: <#referrerDialogRequestId description#>
            public init(namespace: String, name: String, version: String, dialogRequestId: String, messageId: String, referrerDialogRequestId: String? = nil) {
                self.namespace = namespace
                self.name = name
                self.version = version
                self.dialogRequestId = dialogRequestId
                self.messageId = messageId
                self.referrerDialogRequestId = referrerDialogRequestId
            }
        }
        
        /// <#Description#>
        public let payload: [String: AnyHashable]
        /// <#Description#>
        public let header: Header
        /// <#Description#>
        public let httpHeaderFields: [String: String]?
        /// <#Description#>
        public let contextPayload: [ContextInfo]
        
        /// <#Description#>
        /// - Parameters:
        ///   - payload: <#payload description#>
        ///   - header: <#header description#>
        ///   - httpHeaderFields: <#httpHeaderFields description#>
        ///   - contextPayload: <#contextPayload description#>
        public init(payload: [String: AnyHashable], header: Header, httpHeaderFields: [String: String]? = nil, contextPayload: [ContextInfo]) {
            self.payload = payload
            self.header = header
            self.httpHeaderFields = httpHeaderFields
            self.contextPayload = contextPayload
        }
    }
    
    // MARK: Attachment
    
    /// <#Description#>
    public struct Attachment {
        /// <#Description#>
        public struct Header {
            /// <#Description#>
            public let seq: Int32
            /// <#Description#>
            public let isEnd: Bool
            /// <#Description#>
            public let type: String
            /// <#Description#>
            public let messageId: String
            
            /// <#Description#>
            /// - Parameters:
            ///   - seq: <#seq description#>
            ///   - isEnd: <#isEnd description#>
            ///   - type: <#type description#>
            ///   - messageId: <#messageId description#>
            public init(seq: Int32, isEnd: Bool, type: String, messageId: String) {
                self.seq = seq
                self.isEnd = isEnd
                self.type = type
                self.messageId = messageId
            }
        }
        
        /// <#Description#>
        public let content: Data
        /// <#Description#>
        public let header: Header
        
        /// <#Description#>
        /// - Parameters:
        ///   - content: <#content description#>
        ///   - header: <#header description#>
        public init(content: Data, header: Header) {
            self.content = content
            self.header = header
        }
    }
}

// MARK: - Upstream.Event

extension Upstream.Event {
    var headerString: String {
        guard let data = try? JSONEncoder().encode(header),
            let jsonString = String(data: data, encoding: .utf8) else {
                return ""
        }
        
        return jsonString
    }
    
    var payloadString: String {
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
            let payloadString = String(data: data, encoding: .utf8) else {
                return ""
        }
        
        return payloadString
    }
    
    var contextString: String {
        let contextDictionary = Dictionary(grouping: contextPayload, by: { $0.contextType })
        let supportedInterfaces = contextDictionary[.capability]?.reduce(
            into: [String: AnyHashable]()
        ) { result, context in
            result[context.name] = context.payload
        }
        var client: [String: AnyHashable] = ["os": "iOS"]
        contextDictionary[.client]?.forEach({ (contextInfo) in
            client[contextInfo.name] = contextInfo.payload
        })
        
        let contextDict: [String: AnyHashable] = [
            "supportedInterfaces": supportedInterfaces,
            "client": client
        ]
        
        guard
            let data = try? JSONSerialization.data(withJSONObject: contextDict.compactMapValues { $0 }, options: []),
            let contextString = String(data: data, encoding: .utf8) else {
                return ""
        }
        
        return contextString
    }
}

// MARK: - Upstream.Attachment + CustomStringConvertible

extension Upstream.Attachment: CustomStringConvertible {
    public var description: String {
        return "\(header))"
    }
}
