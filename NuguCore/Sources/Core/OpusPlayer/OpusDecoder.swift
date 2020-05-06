//
//  OpusDecoder.swift
//  NuguCore
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

/**
 Swift wrapper using OPUS library
 - If target os is iOS11 or higher, OPUS libraries is not needed because AVAudioConverter can decode it.
 - But, we want to support iOS10 also.
 */
public class OpusDecoder {
    let decoder: OpaquePointer?
    
    public init(sampleRate: Double, channels: Int) {
        decoder = opus_decoder_create(Int32(sampleRate), Int32(channels), nil)
    }
    
    /**
     Decode OPUS data to PCM data.
     - AVAudioPlayerNode can play 32bit audio only. so we ought to convert 16bit opus data to 32bit data.
     - parameter data: OPUS data
     - returns: PCM Sample array
     */
    func decode(data: Data) throws -> [Float] {
        guard let decoder = decoder else {
            print("decoder is not initialized")
            throw OpusPlayerError.decodeFailed
        }
        
        var decodedSamples = [Float](repeating: 0, count: data.count*3)
        let result = opus_decode_float(decoder, [CUnsignedChar](data), CInt(data.count), &decodedSamples, CInt(decodedSamples.count), 0)
        guard 0 < result else {
            print("decode failed, data size:\(data.count), opus error code: \(result)")
            throw OpusPlayerError.decodeFailed
        }

        return decodedSamples
    }
}
