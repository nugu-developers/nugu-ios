//
//  MockAudioStream.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2020/03/02.
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

import NuguCore

class MockAudioStream: AudioStreamable {
    func makeAudioStreamWriter() -> AudioStreamWritable {
        return MockAudioStreamWritable()
    }
    
    func makeAudioStreamReader() -> AudioStreamReadable {
        return MockAudioStreamReadable()
    }
}

class MockAudioStreamReadable: AudioStreamReadable {
    func read(complete: @escaping (Result<AVAudioPCMBuffer, Error>) -> Void) {
        complete(.success(AVAudioPCMBuffer()))
    }
    
}

class MockAudioStreamWritable: AudioStreamWritable {
    func write(_ element: AVAudioPCMBuffer) throws {
        //
    }
    
    func finish() {
        //
    }
}
