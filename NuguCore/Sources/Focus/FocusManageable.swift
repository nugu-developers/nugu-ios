//
//  FocusManageable.swift
//  NuguCore
//
//  Created by MinChul Lee on 19/04/2019.
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

/// A FocusManager takes requests to acquire and release Channels and updates the focuses of other Channels based on
/// their priorities so that the invariant that there can only be one Foreground Channel is held.
public protocol FocusManageable: AnyObject {
    /// The object that acts as the delegate of focus-manager
    var delegate: FocusDelegate? { get set }
    
    /// Register FocusChannelDelegate to FocusManager.
    /// - Parameter channelDelegate: The object to register.
    func add(channelDelegate: FocusChannelDelegate)
    
    /// Unregister FocusChannelDelegate from FocusManager.
    /// - Parameter channelDelegate: The object to unregister.
    func remove(channelDelegate: FocusChannelDelegate)
    
    /// This method will acquire the channel and prepare focus to it.
    ///
    /// The caller will be notified via an focusChannelDidChange:focusState:
    /// - Parameter channelDelegate: The object to prepare focus.
    func prepareFocus(channelDelegate: FocusChannelDelegate)
    
    /// This method will release the prepared channel.
    ///
    /// The caller will be notified via an focusChannelDidChange:focusState:
    /// If the Channel to release is the current foreground focused Channel, it will also notify the next highest priority
    /// Channel via an focusChannelDidChange:focusState: callback that it has gained foreground focus.
    /// - Parameter channelDelegate: The object to release focus.
    func cancelFocus(channelDelegate: FocusChannelDelegate)
    
    /// This method will acquire the channel and grant the appropriate focus to it and other channels if needed.
    ///
    /// The caller will be notified via an focusChannelDidChange:focusState:
    /// If the Channel was already held by a different observer, the observer will be
    /// notified via focusChannelDidChange:focusState: to stop before letting the new observer start.
    /// - Parameter channelDelegate: The object to request focus.
    func requestFocus(channelDelegate: FocusChannelDelegate)
    
    /// This method will release the Channel and notify the observer of the Channel.
    ///
    /// The caller will be notified via an focusChannelDidChange:focusState:
    /// If the Channel to release is the current foreground focused Channel, it will also notify the next highest priority
    /// Channel via an focusChannelDidChange:focusState: callback that it has gained foreground focus.
    /// - Parameter channelDelegate: The object to release focus.
    func releaseFocus(channelDelegate: FocusChannelDelegate)
}
