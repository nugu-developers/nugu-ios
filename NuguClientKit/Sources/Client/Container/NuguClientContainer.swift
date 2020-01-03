//
//  NuguClientContainer.swift
//  NuguClientKit
//
//  Created by yonghoonKwon on 2019/12/11.
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

/// <#Description#>
public protocol NuguClientContainer {
    /// <#Description#>
    var authorizationStore: AuthorizationStoreable { get }
    /// <#Description#>
    var focusManager: FocusManageable { get }
    /// <#Description#>
    var networkManager: NetworkManageable { get }
    /// <#Description#>
    var dialogStateAggregator: DialogStateAggregatable { get }
    /// <#Description#>
    var contextManager: ContextManageable { get }
    /// <#Description#>
    var playSyncManager: PlaySyncManageable { get }
    /// <#Description#>
    var directiveSequencer: DirectiveSequenceable { get }
    /// <#Description#>
    var streamDataRouter: StreamDataRoutable { get }
    /// <#Description#>
    var mediaPlayerFactory: MediaPlayerFactory { get }
    /// <#Description#>
    var sharedAudioStream: AudioStreamable { get }
    /// <#Description#>
    var inputProvider: AudioProvidable { get }
    /// <#Description#>
    var endPointDetector: EndPointDetectable { get }
}
