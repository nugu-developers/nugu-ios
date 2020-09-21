//
//  SktOpusParser.swift
//  NuguAgents
//
//  Created by childc on 2020/04/21.
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

/**
 Extract opus-encoded data from NUGU-custom-packetized data stream
 */
class SktOpusParser {
    static let headerSize = 8
    static let contentSizeIndicatorByteCount = 4
    static let rangeIndicatorByteCount = 4
    
    /**
     Parse Nugu TTS attachment.
     
     - parameter from: Received data from NUGU Server.
     - returns: Opus codec data array
     */
    static func parse(from data: Data) -> [Data] {
        var packetizedDataStream = data
        var opusDataChunkArray = [Data]()
        
        while Self.headerSize < packetizedDataStream.count {
            // parse header
            // get content size
            let contentSizeData: Data = packetizedDataStream.subdata(in: 0..<Self.contentSizeIndicatorByteCount)
            let contentSize = Int(contentSizeData[3]) | (Int(contentSizeData[2]) << 8) | (Int(contentSizeData[1]) << 16) | (Int(contentSizeData[0]) << 24)
            
            // garbage from server. (we don't know the reason why this useless byte is sent by server)
//            let rangeData = packetizedDataStream.subdata(in: Self.contentSizeIndicatorByteCount..<Self.headerSize)
//            let range = Int(rangeData[3]) | (Int(rangeData[2]) << 8) | (Int(rangeData[1]) << 16) | (Int(rangeData[0]) << 24)
//            log.debug("contentSize: \(contentSize), range: \(range), remainedData: \(packetizedDataStream.count)")
            packetizedDataStream = packetizedDataStream.subdata(in: Self.headerSize..<packetizedDataStream.count)
            
            // extract payload.
            let payloadSize = min(contentSize, packetizedDataStream.count)
            let payload = packetizedDataStream.subdata(in: 0..<payloadSize)
            packetizedDataStream = packetizedDataStream.subdata(in: payloadSize..<packetizedDataStream.count)
            
            opusDataChunkArray.append(payload)
        }
        
        return opusDataChunkArray
    }
}
