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

public enum Upstream {
    
    // MARK: Event
    
    public struct Event {
        public struct Header: Encodable {
            public let namespace: String
            public let name: String
            public let version: String
            public let dialogRequestId: String
            public let messageId: String
            public let referrerDialogRequestId: String?
            
            public init(namespace: String, name: String, version: String, dialogRequestId: String, messageId: String, referrerDialogRequestId: String? = nil) {
                self.namespace = namespace
                self.name = name
                self.version = version
                self.dialogRequestId = dialogRequestId
                self.messageId = messageId
                self.referrerDialogRequestId = referrerDialogRequestId
            }
        }
        
        public let payload: [String: AnyHashable]
        public let header: Header
        public let httpHeaderFields: [String: String]?
        public let contextPayload: [ContextInfo]
        
        public init(payload: [String: AnyHashable], header: Header, httpHeaderFields: [String: String]? = nil, contextPayload: [ContextInfo]) {
            self.payload = payload
            self.header = header
            self.httpHeaderFields = httpHeaderFields
            self.contextPayload = contextPayload
        }
    }
    
    // MARK: Attachment
    
    public struct Attachment {
        public struct Header {
            public let seq: Int32
            public let isEnd: Bool
            public let type: String
            public let messageId: String
            
            public init(seq: Int32, isEnd: Bool, type: String, messageId: String) {
                self.seq = seq
                self.isEnd = isEnd
                self.type = type
                self.messageId = messageId
            }
        }
        
        public let content: Data
        public let header: Header
        
        public init(content: Data, header: Header) {
            self.content = content
            self.header = header
        }
    }
}

// MARK: - Upstream.Event

extension Upstream.Event {
    var headerString: String {
        let jsonData: Data
        
        do {
            jsonData = try JSONEncoder().encode(header)
        } catch {
            log.debug("Failed to encoding")
            return ""
        }
        
        let jsonString = String(decoding: jsonData, as: UTF8.self)
        return jsonString
    }
    
    var payloadString: String {
        guard
            let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
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
