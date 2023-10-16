//
//  AudioSessionManageable.swift
//  NuguClientKit
//
//  Created by MinChul Lee on 2021/01/14.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
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

public protocol AudioSessionManageable: AnyObject {
    var delegate: AudioSessionManagerDelegate? { get set }
    
    func isCarplayConnected() -> Bool
    func requestRecordPermission(_ response: @escaping (Bool) -> Void)
    @discardableResult func updateAudioSessionToPlaybackIfNeeded(mixWithOthers: Bool) -> Bool
    @discardableResult func updateAudioSessionWhenCarplayConnected(requestingFocus: Bool) -> Bool
    @discardableResult func updateAudioSession(requestingFocus: Bool) -> Bool
    func notifyAudioSessionDeactivation()
    
    func enable()
    func disable()
}

public extension AudioSessionManageable {
    @discardableResult func updateAudioSessionToPlaybackIfNeeded() -> Bool {
        updateAudioSession(requestingFocus: false)
    }
    
    @discardableResult func updateAudioSession() -> Bool {
        updateAudioSession(requestingFocus: false)
    }
}
