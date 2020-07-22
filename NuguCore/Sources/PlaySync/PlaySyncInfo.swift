//
//  PlaySyncInfo.swift
//  NuguCore
//
//  Created by MinChul Lee on 2019/07/16.
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

public struct PlaySyncInfo {
    public let playServiceId: String
    public let playStackServiceId: String?
    public let dialogRequestId: String
    public let messageId: String
    public let duration: TimeIntervallic
    
    public init(
        playServiceId: String,
        playStackServiceId: String?,
        dialogRequestId: String,
        messageId: String,
        duration: TimeIntervallic
    ) {
        self.playServiceId = playServiceId
        self.playStackServiceId = playStackServiceId
        self.dialogRequestId = dialogRequestId
        self.messageId = messageId
        self.duration = duration
    }
}

// MARK: - CustomStringConvertible

extension PlaySyncInfo: CustomStringConvertible {
    public var description: String {
        return playServiceId
    }
}
