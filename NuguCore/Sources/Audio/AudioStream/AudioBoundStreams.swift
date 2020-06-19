//
//  AudioBoundStreams.swift
//  NuguCore
//
//  Created by childc on 2020/01/20.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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

public class AudioBoundStreams: NSObject, StreamDelegate {
    private static var nextId = 0
    private var id: Int
    private let streams = BoundStreams()
    private let audioStreamReader: AudioStreamReadable
    private let streamQueue: DispatchQueue
    private let streamSemaphore = DispatchSemaphore(value: 0)
    
    public var input: InputStream {
        return streams.input
    }
    
    public init(audioStreamReader: AudioStreamReadable) {
        self.audioStreamReader = audioStreamReader
        self.id = Self.nextId
        Self.nextId += 1
        self.streamQueue = DispatchQueue(label: "com.sktelecom.romaine.audio_bound_stream_queue_\(self.id)")
        super.init()
        log.debug("[\(id)] initiated")

        CFWriteStreamSetDispatchQueue(streams.output, streamQueue)
        streams.output.delegate = self
        streams.output.open()
    }
    
    public func stop() {
        log.debug("[\(id)] bound stream try to stop")
        
        if streams.output.streamStatus != .closed {
            streams.output.close()
            streams.output.delegate = nil
            log.debug("[\(id)] bounded output stream is closed")
        }

        // To cancel running task (audioStreamReader.read)
        streamSemaphore.signal()
    }
    
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasSpaceAvailable:
            guard let audioStreamReader = audioStreamReader as? SharedBuffer<AVAudioPCMBuffer>.Reader else {
                return
            }

            audioStreamReader.read(complete: { [weak self] (result) in
                guard let self = self else { return }
                guard case let .success(pcmBuffer) = result else {
                    log.debug("[\(self.id)] audio stream read failed in hasSpaceAvailable")
                    self.stop()
                    self.streamSemaphore.signal()
                    return
                }
                
                guard let data = pcmBuffer.int16ChannelData?.pointee else {
                    log.debug("[\(self.id)] pcm puffer is not suitable in hasSpaceAvailable")
                    self.streamSemaphore.signal()
                    return
                }
                
                data.withMemoryRebound(to: UInt8.self, capacity: Int(pcmBuffer.frameLength*2)) { (ptrData: UnsafeMutablePointer<UInt8>) -> Void in
                    self.streams.output.write(ptrData, maxLength: Int(pcmBuffer.frameLength*2))
                }
                
                self.streamSemaphore.signal()
            })
            
            streamSemaphore.wait()
            
        case .endEncountered:
            log.debug("[\(id)] output stream endEncountered")
            stop()

        default:
            break
        }
    }
}
