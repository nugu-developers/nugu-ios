//
//  EndPointDetectable.swift
//  NuguInterface
//
//  Created by DCs-OfficeMBP on 16/05/2019.
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

/// <#Description#>
public protocol EndPointDetectable: class {
    /// <#Description#>
    var state: EndPointDetectorState { get set }
    /// <#Description#>
    var epdFile: URL? { get set }
    /// <#Description#>
    var delegate: EndPointDetectorDelegate? { get set }
    
    /// <#Description#>
    /// - Parameters:
    ///   - inputStream: input source.
    ///   - sampleRate: input source's sample rate.
    ///   - timeout: Max duration of waiting for speech.
    ///   - maxDuration: Max duration from speech start to end.
    ///   - pauseLength: The engine waits this time then consider speech end.
    func start(inputStream: AudioStreamReadable,
               sampleRate: Double,
               timeout: Int,
               maxDuration: Int,
               pauseLength: Int)

    /// <#Description#>
    func stop()
}
