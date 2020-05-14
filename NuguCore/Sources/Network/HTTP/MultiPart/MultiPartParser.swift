//
//  MultiPartParser.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 23/07/2019.
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

class MultiPartParser {
    let boundary: String
    
    init(boundary: String) {
        self.boundary = "--"+boundary
    }
    
    func parse(data: Data) throws -> Part {
        guard boundary.count < data.count else {
            throw MultiPartParserError.noData
        }
        
        guard let separatorIndex = findSeparatorIndex(from: data) else {
            throw MultiPartParserError.noData
        }
        
        let partHeader = try parsePartHeader(data: data[0..<separatorIndex+2])
        guard let strContentSize = partHeader["Content-Length"], let contentSize = Int(strContentSize) else {
            throw MultiPartParserError.noData
        }

        let partBody: Data = data.subdata(in: (separatorIndex+4)..<(separatorIndex+4+contentSize))
        let part = Part(header: partHeader, body: partBody)
        
        return part
    }
    
    func separateParts(data: Data) -> ([Data], Int) {
        var remainedData = data
        var parts = [Data]()
        
        while true {
            guard let boundaryRange = remainedData.range(of: boundary.data(using: .utf8)!) else {
                break
            }
            
            parts.append(remainedData[0..<boundaryRange.lowerBound])
            remainedData = remainedData.subdata(in: boundaryRange.upperBound+2..<remainedData.count)
        }
       
        return (parts, data.count - remainedData.count)
    }
    
    private func findSeparatorIndex(from data: Data) -> Int? {
        return data.range(of: (HTTPConst.crlf + HTTPConst.crlf).data(using: .utf8)!)?.lowerBound
    }
    
    private func parsePartHeader(data: Data) throws -> [String: String] {
        var header = [String: String]()
        var headerData = data
        
        while true {
            guard headerData.range(of: HTTPConst.crlf.data(using: .utf8)!) != nil else {
                return header
            }
            
            guard let headerKey = scanString(on: headerData, before: HTTPConst.colon) else {
                throw NetworkError.invalidMessageReceived
            }
            headerData.removeSubrange(0..<(headerKey.count+2))
            
            guard let headerValue = scanString(on: headerData, before: HTTPConst.carriageReturn) else {
                throw NetworkError.invalidMessageReceived
            }
            headerData.removeSubrange(0..<(headerValue.count+2))
            
            header[headerKey] = headerValue
        }
        
        return header
    }
    
    private func scanString(on data: Data, before target: UInt8) -> String? {
        guard let targetIndex = data.firstIndex(of: target) else {
            return nil
        }
        
        return String(data: data[0..<targetIndex], encoding: .utf8)
    }
}

extension MultiPartParser {
    struct Part {
        public let header: [String: String]
        public let body: Data
    }
}
