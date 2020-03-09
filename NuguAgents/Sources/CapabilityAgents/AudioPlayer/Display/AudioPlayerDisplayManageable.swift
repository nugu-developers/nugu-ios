//
//  AudioPlayerDisplayManageable.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2019/07/17.
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

import NuguCore

/// The `AudioPlayerAgent` handles directives for controlling player template display.
protocol AudioPlayerDisplayManageable: PlaySyncDelegate {
    var playSyncManager: PlaySyncManageable! { get set }
    
    func display(metaData: [String: Any], messageId: String, dialogRequestId: String, playStackServiceId: String?)
    
    func updateMetadata(payload: String, playServiceId: String)
    
    func showLylics(playServiceId: String) -> Bool
    
    func hideLylics(playServiceId: String) -> Bool
    
    func controlLylicsPage(payload: String, playServiceId: String) -> Bool
    
    /// Adds a delegate to be notified of `AudioPlayerDisplayTemplate` changes.
    ///
    /// - Parameter delegate: The object to add.
    func add(delegate: AudioPlayerDisplayDelegate)
    
    /// Removes a delegate from `AudioPlayerDisplayManager`.
    ///
    /// - Parameter delegate: The object to remove.
    func remove(delegate: AudioPlayerDisplayDelegate)
    
    /// Stops the timer for deleting template by timeout.
    ///
    /// - Parameter templateId: The unique identifier for the template.
    func stopRenderingTimer(templateId: String)
}
