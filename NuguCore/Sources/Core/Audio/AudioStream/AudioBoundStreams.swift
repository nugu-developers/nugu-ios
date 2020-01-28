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

import NuguInterface

public class AudioBoundStreams: NSObject, StreamDelegate {
    private let streams = BoundStreams()
    private var audioStreamReader: AudioStreamReadable?
    private let streamQueue = DispatchQueue(label: "com.sktelecom.romaine.audio_bound_stream_queue")
    private var streamWorkItem: DispatchWorkItem?
    private let streamSemaphore = DispatchSemaphore(value: 0)
    
    public var input: InputStream {
        return streams.input
    }
    
    public init(audioStreamReader: AudioStreamReadable) {
        self.audioStreamReader = audioStreamReader
        super.init()
        
        log.debug("initiated")
        
        streamWorkItem = DispatchWorkItem { [weak self] in
            log.debug("bound stream task start")
            guard let self = self else { return }
            log.debug("bound stream task is eligible for running")

            self.streams.output.delegate = self
            self.streams.output.schedule(in: .current, forMode: .default)
            self.streams.output.open()
            
            while self.streamWorkItem?.isCancelled == false {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 1))
            }

            log.debug("bound stream task is going to stop")
        }
        streamQueue.async(execute: streamWorkItem!)
    }
    
    public func stop() {
        log.debug("bound stream try to stop")
        streamWorkItem?.cancel()
        streamSemaphore.signal()
        streams.output.close()
        streamQueue.async { [weak self] in
            guard let self = self else { return }

            self.audioStreamReader = nil
            log.debug("bound stream is stopped")
        }
    }
    
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasSpaceAvailable:
            audioStreamReader?.read(complete: { [weak self] (result) in
                guard let self = self else { return }
                
                guard case let .success(pcmBuffer) = result else {
                    log.debug("audio stream read failed in hasSpaceAvailable")
                    self.stop()
                    self.streamSemaphore.signal()
                    return
                }
                
                guard let data = pcmBuffer.int16ChannelData?.pointee else {
                    log.debug("pcm puffer is not suitable in hasSpaceAvailable")
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
            log.debug("output stream endEncountered")
            stop()

        default:
            break
        }
    }
}
