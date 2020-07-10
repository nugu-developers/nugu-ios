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

public class AudioBoundStreams {
    private static var nextId = 0
    private var id: Int
    private let streams = BoundStreams()
    private var streamDelegator: OutputStreamDelegator?
    private let audioStreamReader: AudioStreamReadable
    private let streamQueue: DispatchQueue
    
    public var input: InputStream {
        return streams.input
    }
    
    public init(audioStreamReader: AudioStreamReadable) {
        self.audioStreamReader = audioStreamReader
        self.id = Self.nextId
        Self.nextId += 1
        self.streamQueue = DispatchQueue(label: "com.sktelecom.romaine.audio_bound_stream_queue_\(self.id)")
        log.debug("[\(id)] initiated")
        
        streamQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.streamDelegator = OutputStreamDelegator(owner: self)
            CFWriteStreamSetDispatchQueue(self.streams.output, self.streamQueue)
            self.streams.output.delegate = self.streamDelegator
            self.streams.output.open()
        }
    }
    
    public func stop() {
        log.debug("[\(id)] bound stream try to stop")
        
        streamQueue.async { [weak self] in
            self?.internalStop()
        }
    }
    
    private func internalStop() {
        if streams.output.streamStatus != .closed {
            streams.output.close()
            streams.output.delegate = nil
            log.debug("[\(id)] bounded output stream is closed")
        }
        
        streamDelegator = nil
    }
}

// MARK: - StreamDelegate

extension AudioBoundStreams {
    private class OutputStreamDelegator: NSObject, StreamDelegate {
        let owner: AudioBoundStreams
        private let streamSemaphore = DispatchSemaphore(value: 0)
        
        init(owner: AudioBoundStreams) {
            self.owner = owner
        }
        
        public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
            switch eventCode {
            case .hasSpaceAvailable:
                owner.audioStreamReader.read(complete: { [weak self] (result) in
                    guard let self = self else { return }
                    guard case let .success(pcmBuffer) = result else {
                        log.debug("[\(self.owner.id)] audio stream read failed in hasSpaceAvailable")
                        self.owner.internalStop()
                        self.streamSemaphore.signal()
                        return
                    }
                    
                    guard let data = pcmBuffer.int16ChannelData?.pointee else {
                        log.debug("[\(self.owner.id)] pcm puffer is not suitable in hasSpaceAvailable")
                        self.streamSemaphore.signal()
                        return
                    }
                    
                    data.withMemoryRebound(to: UInt8.self, capacity: Int(pcmBuffer.frameLength*2)) { (ptrData: UnsafeMutablePointer<UInt8>) -> Void in
                        self.owner.streams.output.write(ptrData, maxLength: Int(pcmBuffer.frameLength*2))
                    }
                    
                    self.streamSemaphore.signal()
                })
                
                streamSemaphore.wait()
                
            case .endEncountered:
                log.debug("[\(self.owner.id)] output stream endEncountered")
                fallthrough
            case .errorOccurred:
                self.owner.internalStop()
                
            default:
                break
            }
        }
    }
}
