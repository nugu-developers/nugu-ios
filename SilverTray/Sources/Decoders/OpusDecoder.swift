//
//  OpusDecoder.swift
//  SilverTray
//
//  Created by childc on 28/01/2019.
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
import os.log

import OpusSDK

/**
 Swift wrapper using OPUS library
 - If target os is iOS11 or higher, OPUS libraries is not needed because AVAudioConverter can decode it.
 - But, we want to support iOS10 also.
 */
public class OpusDecoder: AudioDecodable {
    public let sampleRate: Double
    public let channels: Int
    let decoder: OpaquePointer?
    
    public init(sampleRate: Double, channels: Int) {
        self.sampleRate = sampleRate
        self.channels = channels
        
        decoder = opus_decoder_create(Int32(sampleRate), Int32(channels), nil)
    }
    
    deinit {
        if let decoder = decoder {
            opus_decoder_destroy(decoder)
        }
    }
    
    /**
     Decode OPUS data to PCM data.
     - AVAudioPlayerNode can play 32bit audio only. so we ought to convert 16bit opus data to 32bit data.
     - parameter data: OPUS data
     - returns: PCM Sample array
     */
    public func decode(data: Data) throws -> [Float] {
        guard let decoder = decoder else {
            os_log("decoder is not initialized", type: .debug)
            throw DataStreamPlayerError.decodeFailed
        }
        
        var decodedSamples = [Float](repeating: 0, count: data.count*3)
        let result = opus_decode_float(decoder, [CUnsignedChar](data), CInt(data.count), &decodedSamples, CInt(decodedSamples.count), 0)
        guard 0 < result else {
            os_log("decode failed, data size: %@, opus error code: %@", type: .debug, data.count, "\(result)")
            throw DataStreamPlayerError.decodeFailed
        }

        return decodedSamples
    }
}

