//
//  AudioProvidable.swift
//  NuguCore
//
//  Created by childc on 06/02/2020.
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

/**
 Audio Provider Protocol
 
 If you want to provide audio data to `AudioStream` from what ever you want (etc. file, network), You can implement class conform this protocol.
 `NuguClient` will use the audio source you want when you set the `inputProvider` as your instance.
 
 - seeAlso: `NuguClient`
 */
public protocol AudioProvidable {
    var isRunning: Bool { get }
    func start(streamWriter: AudioStreamWritable) throws
    func stop()
}
