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

import NuguUtils

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
    let inputStream = DataBoundInputStream(data: Data())
    
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
    }
    
    /**
     Initiate Full Duplex stream and send header and first body of multipart
     
     You can call this api only once. because stream cannot be opened twice or more.
     
     - Parameter event: UpstreamEventMessage you want to send.
     */
    func send(_ event: Upstream.Event) {
        log.debug("[\(id)] try send event")
        inputStream.appendData(makeMultipartData(event))
    }
    
    /**
     Send attachment through pre-opened stream
     */
    public func send(_ attachment: Upstream.Attachment) {
        log.debug("[\(id)] send attachment")
        inputStream.appendData(makeMultipartData(attachment))
    }
    
    /**
     Send delemeter to notify End of Stream and close the stream
     */
    func finish() {
        log.debug("[\(id)] finish")
        
        var partData = Data()
        partData.append(HTTPConst.crlfData)
        partData.append("--\(self.boundary)--".data(using: .utf8)!)
        partData.append(HTTPConst.crlfData)
        
        log.debug("\n\(String(data: partData, encoding: .utf8) ?? "")")
        inputStream.appendData(partData)
        inputStream.lastDataAppended()
        
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
        partData.append("--\(boundary)".data(using: .utf8)!)
        partData.append(HTTPConst.crlfData)

        log.debug("[\(id)] \n\(String(data: partData, encoding: .utf8) ?? "")")
        return partData
    }
    
    func makeMultipartData(_ attachment: Upstream.Attachment) -> Data {
        let headerLines = [
            "Content-Disposition: form-data; name=\"attachment\"; filename=\"\(attachment.seq);\(attachment.isEnd ? "end" : "continued")\"",
            "Content-Type: \(attachment.type)",
            "Message-Id: \(attachment.header.messageId)"
        ]
        
        var partData = Data()
        partData.append(headerLines.joined(separator: (HTTPConst.crlf)).data(using: .utf8)!)
        partData.append(HTTPConst.crlfData)
        partData.append(HTTPConst.crlfData)
        partData.append(attachment.content)
        partData.append(HTTPConst.crlfData)
        partData.append("--\(boundary)".data(using: .utf8)!)
        partData.append(HTTPConst.crlfData)

        log.debug("[\(id)] Data(\(attachment.content)):\n\(String(data: partData, encoding: .utf8) ?? "")")
        return partData
    }
}
