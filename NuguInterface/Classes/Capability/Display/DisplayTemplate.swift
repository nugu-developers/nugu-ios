//
//  DisplayTemplate.swift
//  NuguInterface
//
//  Created by MinChul Lee on 17/05/2019.
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

public struct DisplayTemplate {
    public let type: String
    public let payload: String
    public let templateId: String
    public let dialogRequestId: String
    
    public init(type: String, payload: String, templateId: String, dialogRequestId: String) {
        self.type = type
        self.payload = payload
        self.templateId = templateId
        self.dialogRequestId = dialogRequestId
    }
}

public extension DisplayTemplate {
    private var payloadDictionary: [String: Any]? {
        guard let payloadAsData = payload.data(using: .utf8) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: payloadAsData, options: []) as? [String: Any]
    }
    var token: String? {
        return payloadDictionary?["token"] as? String
    }
    var playServiceId: String? {
        return payloadDictionary?["playServiceId"] as? String
    }
    var duration: String? {
        return payloadDictionary?["duration"] as? String
    }
}
