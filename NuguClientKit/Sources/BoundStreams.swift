//
//  BoundStreams.swift
//  NuguClientKit
//
//  Created by childc on 2019/11/07.
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

class BoundStreams: NSObject, StreamDelegate {
    private static var id = 0
    private var id: Int
    let input: InputStream
    let output: OutputStream
    private let streamQueue = DispatchQueue(label: "com.sktelecom.romaine.bound_stream_queue")
    private var streamWorkItem: DispatchWorkItem?
    private var buffer: AudioStreamReadable?
    private let streamSemaphore = DispatchSemaphore(value: 0)
    
    init(buffer: AudioStreamReadable) {
        id = BoundStreams.id
        
        if BoundStreams.id == Int.max {
            BoundStreams.id = 0
        } else {
            BoundStreams.id += 1
        }
        
        var inputOrNil: InputStream?
        var outputOrNil: OutputStream?
        Stream.getBoundStreams(withBufferSize: 40960,
                               inputStream: &inputOrNil,
                               outputStream: &outputOrNil)
        guard let input = inputOrNil, let output = outputOrNil else {
            fatalError("On return of `getBoundStreams`, both `inputStream` and `outputStream` will contain non-nil streams.")
        }
        
        // configure and open output stream
        
        self.input = input
        self.output = output
        self.buffer = buffer
        
        super.init()
        log.debug("[id: \(id)] initiated")
        
        streamWorkItem = DispatchWorkItem { [weak self] in
            log.debug("[id: \(self?.id ?? -1)] bound stream task start")
            guard let self = self else { return }
            log.debug("[id: \(self.id)] bound stream task is eligible for running")

            output.delegate = self
            output.schedule(in: .current, forMode: .default)
            output.open()
            
            while self.streamWorkItem?.isCancelled == false {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 1))
            }

            log.debug("[id: \(self.id)] bound stream task is going to stop")
        }
        streamQueue.async(execute: streamWorkItem!)
    }
    
    func stop() {
        log.debug("[id: \(id)] bound stream try to stop")
        streamWorkItem?.cancel()
        streamSemaphore.signal()
        output.close()
        streamQueue.async { [weak self] in
            guard let self = self else { return }

            self.buffer = nil
            log.debug("[id: \(self.id)] bound stream is stopped")
        }
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasSpaceAvailable:
            buffer?.read(complete: { [weak self] (result) in
                guard let self = self else { return }
                
                guard case let .success(pcmBuffer) = result else {
                    log.debug("[id: \(self.id)] audio stream read failed in hasSpaceAvailable")
                    self.stop()
                    self.streamSemaphore.signal()
                    return
                }
                
                guard let data = pcmBuffer.int16ChannelData?.pointee else {
                    log.debug("[id: \(self.id)] pcm puffer is not suitable in hasSpaceAvailable")
                    self.streamSemaphore.signal()
                    return
                }
                
                data.withMemoryRebound(to: UInt8.self, capacity: Int(pcmBuffer.frameLength*2)) { (ptrData: UnsafeMutablePointer<UInt8>) -> Void in
                    self.output.write(ptrData, maxLength: Int(pcmBuffer.frameLength*2))
                }
                
                self.streamSemaphore.signal()
            })
            
            streamSemaphore.wait()
            
        case .endEncountered:
            log.debug("[id: \(self.id)] output stream endEncountered")
            stop()

        default:
            break
        }
    }
}
