//
//  DownStreamDataInterpreter.swift
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

import NuguInterface

public class DownStreamDataInterpreter: DownStreamDataInterpretable {
    private let delegates = DelegateSet<DownStreamDataDelegate>()
    
    public init() {}
    
    public func add(delegate: DownStreamDataDelegate) {
        delegates.add(delegate)
    }
    
    public func remove(delegate: DownStreamDataDelegate) {
        delegates.remove(delegate)
    }
    
    public func receiveMessageDidReceive(header: [String: String], body: Data) {
        if let contentType = header["Content-Type"], contentType.contains("application/json") {
            guard let message = DownStream.Message(messageData: body) else {
                log.error("Decode Message failed")
                return
            }
        
            message.directives.forEach { directive in
                delegates.notify { delegate in
                    delegate.downStreamDataDidReceive(directive: directive)
                }
            }
        } else if let attachment = DownStream.Attachment(headerDictionary: header, body: body) {
            delegates.notify { delegate in
                delegate.downStreamDataDidReceive(attachment: attachment)
            }
        } else {
            log.error("Invalid data \(header)")
        }
    }
}

// MARK: - DownStream.Message initializer

extension DownStream.Message {
    init?(messageData: Data) {
        guard let messageDictionary = try? JSONSerialization.jsonObject(with: messageData, options: []) as? [String: Any],
            let messageArray = messageDictionary["directives"] as? [[String: Any]] else {
            return nil
        }
        
        let directivies = messageArray.compactMap { DownStream.Directive(directiveDictionary: $0) }
        self.init(directives: directivies)
    }
}

// MARK: - DownStream.Attachment initializer

extension DownStream.Attachment {
    init?(headerDictionary: [String: String], body: Data) {
        guard let header = DownStream.Header(headerDictionary: headerDictionary),
            let fileInfo = headerDictionary["Filename"]?.split(separator: ";"),
            fileInfo.count == 2,
            let fileSequence = Int(String(fileInfo[0])),
            let mediaType = headerDictionary["Content-Type"],
            let parentMessageId = headerDictionary["Parent-Message-Id"] else {
                return nil
        }
        
        self.init(header: header, seq: fileSequence, content: body, isEnd: fileInfo[1] == "end", parentMessageId: parentMessageId, mediaType: mediaType)
    }
}

// MARK: - DownStream.Directive initializer

extension DownStream.Directive {
    init?(directiveDictionary: [String: Any]) {
        guard let headerDictionary = directiveDictionary["header"] as? [String: Any],
            let headerData = try? JSONSerialization.data(withJSONObject: headerDictionary, options: []),
            let header = try? JSONDecoder().decode(DownStream.Header.self, from: headerData),
            let payloadDictionary = directiveDictionary["payload"] as? [String: Any],
            let payloadData = try? JSONSerialization.data(withJSONObject: payloadDictionary, options: []),
            let payload = String(data: payloadData, encoding: .utf8) else {
                return nil
        }
        
        self.init(header: header, payload: payload)
    }
}

// MARK: - DownStream.Header initializer

extension DownStream.Header {
    init?(headerDictionary: [String: String]) {
        guard let namespace = headerDictionary["Namespace"],
            let name = headerDictionary["Name"],
            let dialogRequestId = headerDictionary["Dialog-Request-Id"],
            let version = headerDictionary["Version"] else {
                return nil
        }
        
        self.init(namespace: namespace, name: name, dialogRequestId: dialogRequestId, messageId: "", version: version)
    }
}
