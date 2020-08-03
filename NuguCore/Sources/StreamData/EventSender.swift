//
//  EventSender.swift
//  NuguCore
//
//  Created by childc on 2020/02/28.
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

import RxSwift

/**
 Send event through Full Duplex stream.
 send MultiPart body and receive MultiPart response.
 
 - Note: You can send event only once. because stream cannot be opened after close.
 */
class EventSender {
    private static var id = 0
    public let id: Int
    private let boundary: String
    private let streamQueue: DispatchQueue
    private var streamDelegator: DataStreamDelegator?
    private let streamStateSubject = BehaviorSubject<Bool>(value: false)
    private let disposeBag = DisposeBag()
    let streams = BoundStreams()
    
    #if DEBUG
    private var sentData = Data()
    #endif
    
    public init(boundary: String) {
        if EventSender.id == Int.max {
            EventSender.id = 0
        }
        self.id = EventSender.id
        EventSender.id += 1
        
        self.boundary = boundary
        streamQueue = DispatchQueue(label: "com.sktelecom.romaine.event_sender_stream_\(boundary)")
        log.debug("[\(id)] initiated")
        
        streamQueue.async { [weak self] in
            guard let self = self else { return }
            log.debug("[\(self.id)] network bound stream task start.")
            
            self.streamDelegator = DataStreamDelegator(sender: self)
            CFWriteStreamSetDispatchQueue(self.streams.output, self.streamQueue)
            self.streams.output.delegate = self.streamDelegator
            self.streams.output.open()
        }
    }
    
    /**
     Initiate Full Duplex stream and send header and first body of multipart
     
     You can call this api only once. because stream cannot be opened twice or more.
     
     - Parameter event: UpstreamEventMessage you want to send.
     */
    func send(_ event: Upstream.Event) -> Completable {
        log.debug("[\(id)] try send event")
        
        return streamStateSubject
            .filter { $0 }
            .take(1)
            .asSingle()
            .flatMapCompletable { [weak self] _ in
                // send UpstreamEventMessage as a part data
                guard let self = self else { return Completable.empty() }
                return self.sendData(self.makeMultipartData(event))
        }
        .subscribeOn(SerialDispatchQueueScheduler(queue: streamQueue, internalSerialQueueName: "\(streamQueue.label)_event_\(event.header.dialogRequestId)"))
    }
    
    /**
     Send attachment through pre-opened stream
     */
    public func send(_ attachment: Upstream.Attachment) -> Completable {
        log.debug("[\(id)] send attachment")
        
        return streamStateSubject
            .filter { $0 }
            .take(1)
            .asSingle()
            .flatMapCompletable { [weak self] _ in
                guard let self = self else { return Completable.empty() }
                return self.sendData(self.makeMultipartData(attachment))
        }
        .subscribeOn(SerialDispatchQueueScheduler(queue: streamQueue, internalSerialQueueName: "\(streamQueue.label)_attachment_\(attachment.header.seq)"))
        
    }
    
    /**
     Send delemeter to notify End of Stream and close the stream
     */
    func finish() {
        log.debug("[\(id)] finish")
        
        streamStateSubject
            .filter { $0 }
            .take(1)
            .asSingle()
            .flatMapCompletable { [weak self] _ in
                guard let self = self else { return Completable.empty() }
                
                var partData = Data()
                partData.append("--\(self.boundary)--".data(using: .utf8)!)
                partData.append(HTTPConst.crlfData)
                
                log.debug("\n\(String(data: partData, encoding: .utf8) ?? "")")
                return self.sendData(partData)
        }
        .subscribeOn(SerialDispatchQueueScheduler(queue: streamQueue, internalSerialQueueName: "\(streamQueue.label)_finish"))
        .subscribe { [weak self] _ in
            guard let self = self else { return }
            
            #if DEBUG
            do {
                let sentFilename = FileManager.default.urls(for: .documentDirectory,
                                                            in: .userDomainMask)[0].appendingPathComponent("sent_event.dat")
                try self.sentData.write(to: sentFilename)
                log.debug("[\(self.id)] sent event data to file :\(sentFilename)")
            } catch {
                log.debug("[\(self.id)] write sent event data failed: \(error)")
            }
            #endif
            
            self.streamStateSubject.dispose()
            self.streams.output.close()
            self.streams.output.delegate = nil
            self.streamDelegator = nil
        }
        .disposed(by: disposeBag)
    }
    
    /**
     Write data to output stream.
     */
    private func sendData(_ data: Data) -> Completable {
        log.debug("[\(id)] try to send data stream")
        
        return Completable.create { [weak self] (event) -> Disposable in
            let disposable = Disposables.create()
            guard let self = self else { return disposable }
            
            #if DEBUG
            self.sentData.append(data)
            #endif
            
            let result = data.withUnsafeBytes { ptrBuffer -> Int in
                guard let ptrData = ptrBuffer.bindMemory(to: UInt8.self).baseAddress else {
                    return -1
                }
                
                return self.streams.output.write(ptrData, maxLength: data.count)
            }
            
            switch result {
            case ..<0:
                guard let error = self.streams.output.streamError else {
                    event(.error(EventSenderError.cannotBindMemory))
                    return disposable
                }
                
                event(.error(EventSenderError.streamError(error)))
            case 0:
                event(.error(EventSenderError.streamBlocked))
            default:
                event(.completed)
            }
            
            return disposable
        }
    }
}

// MARK: - Multipart

private extension EventSender {
    func makeMultipartData(_ event: Upstream.Event) -> Data {
        let bodyData = ("{ \"context\": \(event.contextString)"
            + ",\"event\": {"
            + "\"header\": \(event.headerString)"
            + ",\"payload\": \(event.payloadString) }"
            + " }").data(using: .utf8)!
        
        let headerLines = [
            "Content-Disposition: form-data; name=\"event\"",
            "Content-Type: application/json"
        ]
        
        var partData = Data()
        partData.append("--\(boundary)".data(using: .utf8)!)
        partData.append(HTTPConst.crlfData)
        partData.append(headerLines.joined(separator: (HTTPConst.crlf)).data(using: .utf8)!)
        partData.append(HTTPConst.crlfData)
        partData.append(HTTPConst.crlfData)
        partData.append(bodyData)
        partData.append(HTTPConst.crlfData)
        
        log.debug("[\(id)] \n\(String(data: partData, encoding: .utf8) ?? "")")
        return partData
    }
    
    func makeMultipartData(_ attachment: Upstream.Attachment) -> Data {
        let headerLines = [
            "Content-Disposition: form-data; name=\"attachment\"; filename=\"\(attachment.header.seq);\(attachment.header.isEnd ? "end" : "continued")\"",
            "Content-Type: \(attachment.header.type)",
            "Message-Id: \(attachment.header.messageId)"
        ]
        
        var partData = Data()
        partData.append("--\(boundary)".data(using: .utf8)!)
        partData.append(HTTPConst.crlfData)
        partData.append(headerLines.joined(separator: (HTTPConst.crlf)).data(using: .utf8)!)
        partData.append(HTTPConst.crlfData)
        partData.append(HTTPConst.crlfData)
        partData.append(attachment.content)
        partData.append(HTTPConst.crlfData)
        
        log.debug("[\(id)] Data(\(attachment.content)):\n\(String(data: partData, encoding: .utf8) ?? "")")
        return partData
    }
}

// MARK: - StreamDelegate

extension EventSender {
    private class DataStreamDelegator: NSObject, StreamDelegate {
        private let sender: EventSender
        
        init(sender: EventSender) {
            self.sender = sender
        }
        
        func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
            guard let outputStream = aStream as? OutputStream,
                outputStream === sender.streams.output else {
                    return
            }
            
            switch eventCode {
            case .hasSpaceAvailable:
                sender.streamStateSubject.onNext(true)
            case .endEncountered,
                 .errorOccurred:
                sender.streamStateSubject.onNext(false)
                sender.streamStateSubject.onCompleted()
            default:
                break
            }
        }
    }
}
