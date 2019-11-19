//
//  AudioStream.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 03/05/2019.
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

import NuguInterface

public class AudioStream {
    private let buffer: AudioBuffer
    public weak var delegate: AudioStreamDelegate? {
        didSet {
            buffer.streamDelegate = delegate
        }
    }

    public init(capacity: Int) {
        buffer = AudioBuffer(capacity: capacity)
    }
}

extension AudioStream {
    public class AudioBuffer: SharedBuffer<AVAudioPCMBuffer> {
        public weak var streamDelegate: AudioStreamDelegate?
        private let delegateQueue = DispatchQueue(label: "com.sktelecom.romaine.audio_stream_delegate")
        private var refCnt = 0 {
            didSet {
                log.debug("audio reference count: \(oldValue) -> \(refCnt)")
                switch (oldValue, refCnt) {
                case (_, 0):
                    self.streamDelegate?.audioStreamDidStop()
                case (0, 1):
                    self.streamDelegate?.audioStreamWillStart()
                default:
                    break
                }
            }
        }
        
        private func increaseRef() {
            delegateQueue.async { [weak self] in
                guard let self = self else { return }
                self.refCnt += 1
            }
        }
        
        private func decreaseRef() {
            delegateQueue.async { [weak self] in
                guard let self = self else { return }
                self.refCnt -= 1
            }
        }
        
        public override func makeBufferWriter() -> SharedBuffer<AVAudioPCMBuffer>.Writer {
            let writer = AudioBufferWriter(buffer: self)
            self.writer = writer
            return writer
        }
        
        public class AudioBufferWriter: SharedBuffer<AVAudioPCMBuffer>.Writer {
            /** Copy AVAudioBuffer and store it.
             So, we can have independent life cycle.
             */
            public override func write(_ element: AVAudioPCMBuffer) throws {
                guard let newElement = element.copy() as? AVAudioPCMBuffer else {
                    try super.write(element)
                    return
                }
                
                try super.write(newElement)
            }
        }
        
        public override func makeBufferReader() -> SharedBuffer<AVAudioPCMBuffer>.Reader {
            return AudioBufferReader(buffer: self)
        }
        
        public class AudioBufferReader: SharedBuffer<AVAudioPCMBuffer>.Reader {
            private let audioBuffer: AudioBuffer
            
            init(buffer: AudioBuffer) {
                audioBuffer = buffer
                super.init(buffer: buffer)
                audioBuffer.increaseRef()
            }
            
            deinit {
                audioBuffer.decreaseRef()
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
