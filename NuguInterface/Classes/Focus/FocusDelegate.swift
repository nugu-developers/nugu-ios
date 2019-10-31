//
//  FocusDelegate.swift
//  NuguInterface
//
//  Created by MinChul Lee on 24/04/2019.
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

/// An delegate that appllication can extend to register to observe focus changes.
public protocol FocusDelegate: class {
    /// Determines whether the channel should be acquired focus.
    ///
    /// This mehthod called When the focus manager receives a requestFocus:channelDelegate:
    /// - Parameter channel: The channel which requested focus.
    func focusShouldAcquire(channel: FocusChannelConfigurable) -> Bool
    
    /// Used to notify the observer of focus changes.  This function should return quickly.
    /// - Parameter channel: The channel which changed FocusState.
    /// - Parameter focusState: The new FocusState of channel.
    func focusDidChange(channel: FocusChannelConfigurable, focusState: FocusState)
}
