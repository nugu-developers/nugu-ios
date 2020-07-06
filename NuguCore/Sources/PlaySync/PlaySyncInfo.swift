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

struct PlaySyncInfo {
    let playServiceId: String?
    let dialogRequestId: String
    let duration: DispatchTimeInterval
    
    init(playServiceId: String?, dialogRequestId: String, duration: DispatchTimeInterval) {
        self.playServiceId = playServiceId
        self.dialogRequestId = dialogRequestId
        self.duration = duration
    }
}

// MARK: - CustomStringConvertible

extension PlaySyncInfo: CustomStringConvertible {
    var description: String {
        return playServiceId ?? "PlayServiceId is null"
    }
}
