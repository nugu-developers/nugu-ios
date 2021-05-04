//
//  VoiceChromePresenterDelegate.swift
//  NuguClientKit
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/11/25.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

import NuguUIKit

/// A delegate that application can extend to observe `VoiceChromePresenter` changes.
public protocol VoiceChromePresenterDelegate: AnyObject {
    /// Notifies the `NuguVoiceChrome` to be shown.
    func voiceChromeWillShow()
    
    /// Notifies the `NuguVoiceChrome` to be hidden.
    func voiceChromeWillHide()
    
    /// Determines whether to set `UIApplication.shared.isIdleTimerDisabled` to true.
    func voiceChromeShouldDisableIdleTimer() -> Bool
    
    /// Determines whether to set `UIApplication.shared.isIdleTimerDisabled` to false.
    func voiceChromeShouldEnableIdleTimer() -> Bool
    
    /// Delegate method called when chips has been selected.
    func voiceChromeChipsDidClick(chips: NuguChipsButton.NuguChipsButtonType)
}

public extension VoiceChromePresenterDelegate {
    func voiceChromeShouldDisableIdleTimer() -> Bool {
        return true
    }
    
    func voiceChromeShouldEnableIdleTimer() -> Bool {
        return true
    }
}
