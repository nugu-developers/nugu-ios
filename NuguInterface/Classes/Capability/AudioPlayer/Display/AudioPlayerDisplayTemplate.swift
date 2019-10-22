//
//  AudioPlayerDisplayTemplate.swift
//  NuguInterface
//
//  Created by MinChul Lee on 2019/07/03.
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

public struct AudioPlayerDisplayTemplate {
    public let type: String
    public let typeInfo: TypeInfo
    public let messageId: String
    public let dialogRequestId: String
    public let templateId: String
    
    public init(type: String, typeInfo: TypeInfo, messageId: String, dialogRequestId: String, templateId: String) {
        self.type = type
        self.typeInfo = typeInfo
        self.messageId = messageId
        self.dialogRequestId = dialogRequestId
        self.templateId = templateId
    }
    
    /// The player template of the DisplayPlayerAgent.
    public enum TypeInfo {
        /// A player template for metadata associated with a media item
        /// - Parameter item: Information of the player template.
        case audioPlayer(item: AudioPlayerDisplayTemplate.AudioPlayer)
    }
}
