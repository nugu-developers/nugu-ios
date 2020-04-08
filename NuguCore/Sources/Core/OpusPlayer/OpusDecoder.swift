//
//  OpusDecoder.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 28/01/2019.
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
 Swift wrapper using OPUS library
 - If target os is iOS11 or higher, OPUS libraries is not needed because AVAudioConverter can decode it.
 - But, we want to support iOS10 also.
 */
class OpusDecoder {
    static let shared = OpusDecoder()
    let decoder = opus_decoder_create(Int32(OpusPlayerConst.defaultDecoderSampleRate), 1, nil)
    
    #if DEBUG
    private var originalData = Data()
    #endif
    
    /**
     Decode OPUS data to PCM data.
     - AVAudioPlayerNode can play 32bit audio only. so we ought to convert 16bit opus data to 32bit data.
     - parameter data: OPUS data
     - returns: PCM Sample array
     */
    func decode(data: Data) throws -> [Float] {
        guard let decoder = decoder else {
            log.error("decoder is not initialized")
            throw OpusPlayerError.decodeFailed
        }
        
        var opusData = data
        log.debug("opus data size: \(opusData.count)")
        
        #if DEBUG
        originalData.append(opusData)
        #endif
        
        var totalDecodedBuffer = [Float]()
        while OpusPlayerConst.opusPacketHeaderSize < opusData.count {
            // parse header
            // get content size
            let contentSizeData: Data = opusData.subdata(in: 0..<4)
            let contentSize = Int(contentSizeData[3]) | (Int(contentSizeData[2]) << 8) | (Int(contentSizeData[1]) << 16) | (Int(contentSizeData[0]) << 24)
//            log.debug("opus chunk size: \(contentSize)")
            
            // garbage from server.
//            let rangeData = opusData.subdata(in: 4..<8)
//            let range = Int(rangeData[3]) | (Int(rangeData[2]) << 8) | (Int(rangeData[1]) << 16) | (Int(rangeData[0]) << 24)
            opusData = opusData.subdata(in: 8..<opusData.count)
//            log.debug("packetLength: \(contentSize), range: \(range), sizeToDecode: \(opusData.count)")
            
            // If Header insist to decode more data than remains
            let decodeLength = min(contentSize, opusData.count)
            let payload = opusData.subdata(in: 0..<decodeLength)
            var decodedBuffer = [Float](repeating: 0, count: decodeLength*3)
            let result = opus_decode_float(decoder, [CUnsignedChar](payload), CInt(payload.count), &decodedBuffer, CInt(decodedBuffer.count), 0)
            
            guard 0 < result else {
                log.error("decode failed during decode: \(decodeLength) of opus data")
                log.error("remained opus data: \(String(data: opusData, encoding: .ascii) ?? "")\nsize:\(opusData.count)")
                throw OpusPlayerError.decodeFailed
            }

            totalDecodedBuffer.append(contentsOf: decodedBuffer[..<Int(result)])
            opusData = opusData.subdata(in: payload.count..<opusData.count)
        }
        
        return totalDecodedBuffer
    }
    
    #if DEBUG
    public func dump() {
        let originalFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("silver_tray_opus.opus")
        
        do {
            try originalData.write(to: originalFilename)
            originalData.removeAll()

            log.debug("original opus data file: \(originalFilename)")
        } catch {
            log.error(error)
        }
    }
    #endif
}
