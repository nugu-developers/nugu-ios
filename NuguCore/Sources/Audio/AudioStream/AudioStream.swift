//
//  AudioStream.swift
//  NuguCore
//
//  Created by childc on 03/05/2019.
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
import AVFoundation

/**
 AudioStream made from RingBuffer.
 
 This stream can notify audio stream is needed or not using a delegator
 - seeAlso: AudioStreamDelegate
 */
public class AudioStream {
    private let buffer: AudioBuffer

    public init(capacity: Int) {
        buffer = AudioBuffer(capacity: capacity)
    }
}

extension AudioStream {
    class AudioBuffer: SharedBuffer<AVAudioPCMBuffer> {
        override func makeBufferReader() -> SharedBuffer<AVAudioPCMBuffer>.Reader {
            return AudioBufferReader(buffer: self)
        }
        
        class AudioBufferReader: SharedBuffer<AVAudioPCMBuffer>.Reader {
            private weak var audioBuffer: AudioBuffer?
            
            init(buffer: AudioBuffer) {
                audioBuffer = buffer
                super.init(buffer: buffer)
            }
        }
    }
}

extension AudioStream: AudioStreamable {
    public func makeAudioStreamWriter() -> AudioStreamWritable {
        return buffer.makeBufferWriter()
    }

    public func makeAudioStreamReader() -> AudioStreamReadable {
        return buffer.makeBufferReader()
    }
}

extension SharedBuffer.Reader: AudioStreamReadable where Element == AVAudioPCMBuffer {}
extension SharedBuffer.Writer: AudioStreamWritable where Element == AVAudioPCMBuffer {}
