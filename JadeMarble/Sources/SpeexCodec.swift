//
//  SpeexEncoder.swift
//  JadeMarble
//
//  Created by DCs-OfficeMBP on 18/06/2019.
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

import TycheSDK

public class SpeexEncoder {
    var codecHandle: SpeexHandle
    
    public init(sampleRate: Int, inputType: StreamType) {
        codecHandle = speexSTART(myint(sampleRate), myint(inputType.rawValue), myint(StreamType.speex.rawValue))
    }
    
    deinit {
        speexRELEASE(codecHandle)
    }
    
    public func encode(data: Data) throws -> Data {
        var pcmData = data
        let result = pcmData.withUnsafeMutableBytes { (ptrRawBuffer) -> myint in
            let ptrData = ptrRawBuffer.baseAddress
            return speexRUN(codecHandle, ptrData, Int32(data.count), 0)
        }
        
        guard 0 < result else {
            throw SpeexError.encodeFailed
        }
        
        let ptrEncodedData = UnsafeMutablePointer<mychar>.allocate(capacity: Int(result))
        defer { ptrEncodedData.deallocate() }
        
        speexGetOutputData(codecHandle, ptrEncodedData, result)
        return Data(bytes: ptrEncodedData, count: Int(result))
    }
}
