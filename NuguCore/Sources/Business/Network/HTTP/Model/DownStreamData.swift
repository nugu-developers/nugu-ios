//
//  DownStreamData.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 24/07/2019.
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
import NuguInterface

public struct DownStreamData {
    struct Header: Decodable {
        var namespace: String
        var name: String
        var dialogRequestID: String
        var messageID: String
        var version: String
        
        private enum CodingKeys: String, CodingKey {
            case namespace
            case name
            case dialogRequestID = "dialogRequestId"
            case messageID = "messageId"
            case version
        }
        
        init(namespace: String, name: String, dialogRequestID: String, messageID: String, version: String) {
            self.namespace = namespace
            self.name = name
            self.dialogRequestID = dialogRequestID
            self.messageID = messageID
            self.version = version
        }
    }
        
    struct Message: Decodable {
        var directives: [Directive]
        
        init() {
            directives = []
        }
    }
    
    struct Directive: Decodable, DirectiveProtocol {
        var header: MessageHeaderProtocol
        var payload: String
        
        private enum CodingKeys: String, CodingKey {
            case header
            case payload
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            header = try values.decode(Header.self, forKey: .header)
            
            let payload = try values.decode([String: Any].self, forKey: .payload)
            let jsonPayload = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            self.payload = String(data: jsonPayload, encoding: .utf8) ?? ""
        }
        
        init(header: Header, payload: String) {
            self.header = header
            self.payload = payload
        }
    }
    
    struct Attachment: AttachmentProtocol {
        var header: MessageHeaderProtocol
        var seq: Int
        var content: Data
        var isEnd: Bool
        var parentMessageID: String
        var mediaType: String
    }
}

extension DownStreamData.Header: MessageHeaderProtocol {
    var type: String { "\(namespace).\(name)" }
}
