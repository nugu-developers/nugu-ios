//
//  DataStreamPlayerDelegate.swift
//  SilverTray
//
//  Created by childc on 2020/04/21.
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
import AVFoundation

public protocol DataStreamPlayerDelegate: AnyObject {
    func dataStreamPlayerStateDidChange(_ state: DataStreamPlayerState)
    func dataStreamPlayerBufferStateDidChange(_ state: DataStreamPlayerBufferState)
    func dataStreamPlayerDidPlay(_ chunk: AVAudioPCMBuffer)
    func dataStreamPlayerDidComputeDuration(_ duration: Int)
}

public extension DataStreamPlayerDelegate {
    func dataStreamPlayerDidPlay(_ chunk: AVAudioPCMBuffer) {}
}
