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
    public let typeInfo: TypeInfo
    public let messageId: String
    public let dialogRequestId: String
    
    public init(type: String, typeInfo: TypeInfo, messageId: String, dialogRequestId: String) {
        self.type = type
        self.typeInfo = typeInfo
        self.messageId = messageId
        self.dialogRequestId = dialogRequestId
    }
    
    /// The template of the DisplayAgent.
    public enum TypeInfo {
        /// A text only template that supports image, title, header, body and footer.
        /// - Parameter item: Information of the template.
        case bodyTemplate(item: DisplayTemplate.BodyTemplate)
        /// A template for list of entries.
        /// - Parameter item: Information of the template.
        case listTemplate(item: DisplayTemplate.ListTemplate)
        /// A template for list of entries.
        /// - Parameter item: Information of the template.
        case bodyListTemplate(item: DisplayTemplate.BodyListTemplate)
    }
}

public extension DisplayTemplate {
    var token: String {
        switch typeInfo {
        case .bodyTemplate(let item): return item.token
        case .listTemplate(let item): return item.token
        case .bodyListTemplate(let item): return item.token
        }
    }
    var playServiceId: String {
        switch typeInfo {
        case .bodyTemplate(let item): return item.playServiceId
        case .listTemplate(let item): return item.playServiceId
        case .bodyListTemplate(let item): return item.playServiceId
        }
    }
    var duration: DisplayTemplate.Common.Duration? {
        switch typeInfo {
        case .bodyTemplate(let item): return item.duration
        case .listTemplate(let item): return item.duration
        case .bodyListTemplate(let item): return item.duration
        }
    }
}
