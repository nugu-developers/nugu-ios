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

import NuguInterface

struct PlaySyncInfo {
    // TODO: delegate 를 struct 에서 가지고 있지 않도록 구조 수정.
    weak var delegate: PlaySyncDelegate?
    
    let dialogRequestId: String
    let playServiceId: String
    let playSyncState: PlaySyncState
    let isDisplay: Bool
    let duration: DisplayTemplate.Duration
    
    init(delegate: PlaySyncDelegate, dialogRequestId: String, playServiceId: String, playSyncState: PlaySyncState) {
        self.delegate = delegate
        self.dialogRequestId = dialogRequestId
        self.playServiceId = playServiceId
        self.playSyncState = playSyncState
        self.isDisplay = delegate.playSyncIsDisplay()
        self.duration = delegate.playSyncDuration()
    }
}

// MARK: - PlaySyncInfo + CustomStringConvertible

extension PlaySyncInfo: CustomStringConvertible {
    var description: String {
        if let delegate = delegate {
            return "\nPlaySyncInfo: \(delegate), \(playServiceId), \(playSyncState)"
        } else {
            return ""
        }
    }
}
