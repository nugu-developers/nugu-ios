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
    let input: InputStream
    let output: OutputStream
    private let streamQueue = DispatchQueue(label: "com.sktelecom.romaine.bound_stream_queue")
    private var streamWorkItem: DispatchWorkItem?
    private var buffer: AudioStreamReadable?
    private let streamSemaphore = DispatchSemaphore(value: 0)
    
    init(buffer: AudioStreamReadable) {
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
        
        streamWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            output.delegate = self
            output.schedule(in: .current, forMode: .default)
            output.open()
            
            while RunLoop.current.run(mode: .default, before: .distantFuture) && self.streamWorkItem?.isCancelled == false {}
        }
        streamQueue.async(execute: streamWorkItem!)
    }
    
    func stop() {
        log.debug("bound stream try to stop")
        streamWorkItem?.cancel()
        streamSemaphore.signal()
        output.close()
        streamQueue.async { [weak self] in
            self?.buffer = nil
            log.debug("bound stream is stopped")
        }
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasSpaceAvailable:
            buffer?.read(complete: { [weak self] (result) in
                guard let self = self else { return }
                
                guard case let .success(pcmBuffer) = result else {
                    self.stop()
                    self.streamSemaphore.signal()
                    return
                }
                
                guard let data = pcmBuffer.int16ChannelData?.pointee else {
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
            log.debug("output stream endEncountered")
            stop()

        default:
            break
        }
    }
}
