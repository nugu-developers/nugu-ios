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
class EventSender: NSObject {
    private let boundary: String
    private let eventQueue = DispatchQueue(label: "com.sktelecom.romaine.event_sender_event")
    private let streamQueue: DispatchQueue
    private var streamWorkItem: DispatchWorkItem?
    private let streamStateSubject = BehaviorSubject<Bool>(value: false)
    private let disposeBag = DisposeBag()
    let streams = BoundStreams()
    
    #if DEBUG
    private var sentData = Data()
    #endif
    
    public init(boundary: String) {
        self.boundary = boundary
        streamQueue = DispatchQueue(label: "com.sktelecom.romaine.event_sender_stream_\(boundary)")
        super.init()
        log.debug("initiated")
        
        streamWorkItem = DispatchWorkItem { [weak self] in
            log.debug("network bound stream task start.")
            guard let self = self else { return }
            log.debug("network bound stream task is eligible for running")
            
            self.streams.output.delegate = self
            self.streams.output.schedule(in: .current, forMode: .default)
            self.streams.output.open()
            
            while self.streamWorkItem?.isCancelled == false {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 1))
            }
            
            log.debug("network bound stream task is going to stop")
        }
        streamQueue.async(execute: streamWorkItem!)
    }
    
    /**
     Initiate Full Duplex stream and send header and first body of multipart
     
     You can call this api only once. because stream cannot be opened twice or more.
     
     - Parameter event: UpstreamEventMessage you want to send.
     */
    func send(_ event: Upstream.Event) -> Completable {
        return Completable.create { [weak self] (complete) -> Disposable in
            let disposable = Disposables.create()
            
            // check input stream was opened before.
            guard self?.streams.input.streamStatus == .notOpen else {
                complete(.error(EventSenderError.requestMultipleEvents))
                return disposable
            }
            
            complete(.completed)
            return disposable
        }
        .andThen(self.streamStateSubject)
        .filter { $0 }
        .take(1)
        .asSingle()
        .flatMapCompletable { [weak self] _ in
            // send UpstreamEventMessage as a part data
            guard let self = self else { return Completable.empty() }
            return self.sendData(self.makeMultipartData(event))
        }
        .subscribeOn(SerialDispatchQueueScheduler(queue: eventQueue, internalSerialQueueName: "event_queue_\(event.header.dialogRequestId)"))
    }
    
    /**
     Send attachment through pre-opened stream
     */
    public func send(_ attachment: Upstream.Attachment) -> Completable {
        streamStateSubject
            .filter { $0 }
            .take(1)
            .asSingle()
            .flatMapCompletable { [weak self] _ in
                guard let self = self else { return Completable.empty() }
                return self.sendData(self.makeMultipartData(attachment))
        }
        .subscribeOn(SerialDispatchQueueScheduler(queue: eventQueue, internalSerialQueueName: "attachment_queue_\(attachment.header.seq)"))
        
    }
    
    /**
     Send delemeter to notify End of Stream and close the stream
     */
    func finish() {
        streamStateSubject
            .filter { $0 }
            .take(1)
            .asSingle()
            .flatMapCompletable { [weak self] _ in
                guard let self = self else { return Completable.empty() }
                log.debug("write last boundary: --\(self.boundary)--")
                
                guard let lastBoundaryData = ("--\(self.boundary)--" + HTTPConst.crlf).data(using: .utf8) else { return Completable.empty() }
                return self.sendData(lastBoundaryData)
        }
        .subscribe { [weak self] _ in
            guard let self = self else { return }
            
            #if DEBUG
            do {
                let sentFilename = FileManager.default.urls(for: .documentDirectory,
                                                            in: .userDomainMask)[0].appendingPathComponent("sent_event.dat")
                try self.sentData.write(to: sentFilename)
                log.debug("sent event data to file :\(sentFilename)")
            } catch {
                log.debug("write sent event data failed: \(error)")
            }
            #endif
            
            self.streamStateSubject.dispose()
            self.streamWorkItem?.cancel()
            self.streams.output.close()
        }
        .disposed(by: disposeBag)
    }
    
    /**
     Write data to output stream.
     */
    private func sendData(_ data: Data) -> Completable {
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
        let headerLines = ["--\(boundary)",
            "Content-Disposition: form-data; name=\"event\"",
            "Content-Type: application/json",
            HTTPConst.crlf]
        var partData = headerLines.joined(separator: (HTTPConst.crlf)).data(using: .utf8)!
        
        let bodyData = ("{ \"context\": \(event.contextString)"
            + ",\"event\": {"
            + "\"header\": \(event.headerString)"
            + ",\"payload\": \(event.payloadString) }"
            + " }"
            + HTTPConst.crlf).data(using: .utf8)!
        partData.append(bodyData)
        
        log.debug("\n\(String(data: partData, encoding: .utf8) ?? "")")
        return partData
    }
    
    func makeMultipartData(_ attachment: Upstream.Attachment) -> Data {
        let headerLines = [
            "--\(boundary)",
            "Content-Disposition: form-data; name=\"attachment\"; filename=\"\(attachment.header.seq);\(attachment.header.isEnd ? "end" : "continued")\"",
            "Content-Type: \(attachment.header.type)",
            "Message-Id: \(attachment.header.messageId)",
            HTTPConst.crlf
        ]
        
        var partData = headerLines.joined(separator: (HTTPConst.crlf)).data(using: .utf8)!
        log.debug("Data(\(attachment.content)):\n\(String(data: partData, encoding: .utf8) ?? "")")
        partData.append(attachment.content)
        partData.append(HTTPConst.crlf.data(using: .utf8)!)
        
        return partData
    }
}

// MARK: - StreamDelegate

extension EventSender: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard let outputStream = aStream as? OutputStream,
            outputStream === streams.output else {
                return
        }
        
        switch eventCode {
        case .hasSpaceAvailable:
            streamStateSubject.onNext(true)
        case .endEncountered,
             .errorOccurred:
            streamStateSubject.onNext(false)
            streamStateSubject.onCompleted()
        default:
            break
        }
    }
}
