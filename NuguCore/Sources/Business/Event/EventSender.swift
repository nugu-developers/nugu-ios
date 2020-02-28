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
    private let streams = BoundStreams()
    private let nuguApiProvider: NuguApiProvider
    private let boundary = "dummy-boundary-replace-it" // TODO: create!!
    private let eventQueue = DispatchQueue(label: "com.sktelecom.romaine.event_sender_queue")
    private let eventSemaphore = DispatchSemaphore(value: 0)
    private let streamQueue = DispatchQueue(label: "com.sktelecom.romaine.event_sender_stream_queue")
    private var streamWorkItem: DispatchWorkItem?
    private let streamStateSubject = BehaviorSubject<Bool>(value: false)
    private let disposeBag = DisposeBag()
    
    #if DEBUG
    private var sentData = Data()
    #endif
    
    init(nuguApiProvider: NuguApiProvider) {
        self.nuguApiProvider = nuguApiProvider
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
    
    /**
     Initiate Full Duplex stream and send header and first body of multipart
     
     You can call this api only once. because stream cannot be opened twice or more.
     
     - Parameter event: UpstreamEventMessage you want to send.
     - Parameter completeHandler: It will be called when the event sent.
     - Parameter resultHandler: It can be called multiple time If the reponse causes multple responses.
     */
    func send(_ event: UpstreamEventMessage, resultHandler: ((Result<EventSenderResult, Error>) -> Void)? = nil) {
        eventQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard self.streams.input.streamStatus == .notOpen else {
                resultHandler?(.failure(EventSenderError.requestMultipleEvents))
                return
            }
            
            self.nuguApiProvider.events(inputStream: self.streams.input)
                .subscribe(onNext: { (part) in
                    resultHandler?(.success(.received(part: part)))
                }, onError: { (error) in
                    log.error("error: \(error)")
                    resultHandler?(.failure(error))
                }, onDisposed: {
                    log.debug("disposed")
                    resultHandler?(.success(.finished))
                })
                .disposed(by: self.disposeBag)
            
            self.streamStateSubject
                .filter { $0 == true }
                .take(1)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    
                    let result = self.sendData(self.makeMultipartData(event))
                        .map { _ in EventSenderResult.sent }
                        .mapError { $0 as Error }
                    resultHandler?(result)

                    self.eventSemaphore.signal()
                })
                .disposed(by: self.disposeBag)
            
            self.eventSemaphore.wait()
        }
    }
    
    /**
     Send attachment through pre-opened stream
     - Parameter completeHandler: It will be called when the attachment sent.
     */
    public func send(_ attachment: UpstreamAttachment, completeHandler: ((Result<Void, Error>) -> Void)? = nil) {
        self.streamStateSubject
            .filter { $0 == true }
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                completeHandler?(self.sendData(self.makeMultipartData(attachment)).mapError { $0 as Error })
            })
            .disposed(by: self.disposeBag)
    }
    
    @discardableResult private func sendData(_ data: Data) -> Result<Void, EventSenderError> {
        #if DEBUG
        sentData.append(data)
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
                return .failure(.cannotBindMemory)
            }

            return .failure(.streamError(error))
        case 0:
            return .failure(.streamBlocked)
        default:
            return .success(())
        }
    }
    
    /**
     Send delemeter to notify End of Stream and close the stream
     */
    func finish() {
        streamStateSubject
            .filter { $0 }
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                log.debug("write last boundary: --\(self.boundary)--")
                
                guard let lastBoundaryData = ("--\(self.boundary)--" + HTTPConst.crlf).data(using: .utf8) else { return }
                if case .failure(let error) = self.sendData(lastBoundaryData) {
                    log.error("send last boundary failed with \(error). but stream will be closed")
                }
                
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
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - State

extension EventSender {
    enum EventSenderResult {
        case sent
        case received(part: MultiPartParser.Part)
        case finished
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
            log.debug("hasSpaceAvailable")
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

// MARK: - Multipart

private extension EventSender {
    func makeMultipartData(_ event: UpstreamEventMessage) -> Data {
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

        return partData
    }
    
    func makeMultipartData(_ attachment: UpstreamAttachment) -> Data {
        let headerLines = [
            "--\(boundary)",
            "Content-Disposition: form-data; name=\"attachment\"; filename=\"\(attachment.seq);\(attachment.isEnd ? "end" : "continued")\"",
//            "Content-Type: \(attachment.type)", // TODO: server에서 content-type 제대로 구현하면 변경할 것.
            "Content-Type: application/octet-stream",
            HTTPConst.crlf
        ]
        
        var partData = headerLines.joined(separator: (HTTPConst.crlf)).data(using: .utf8)!
        partData.append(attachment.content)
        partData.append(HTTPConst.crlf.data(using: .utf8)!)
        
        return partData
    }
}
