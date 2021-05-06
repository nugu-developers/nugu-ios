//
//  MultiPartProcessable.swift
//  NuguCore
//
//  Created by childc on 2020/03/05.
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

import RxSwift

protocol MultiPartProcessable: AnyObject {
    var parser: MultiPartParser? { get set }
    var data: Data { get set }
    var subject: PublishSubject<Data> { get }
}

extension MultiPartProcessable {
    func parseData() -> [MultiPartParser.Part]? {
        guard let parser = self.parser else {
            return nil
        }
            
        let (parts, size) = parser.separateParts(data: self.data)
        guard 0 < size else { return nil }
        
        var multiPart = [MultiPartParser.Part]()
        do {
            try parts.forEach { (data) in
                guard 0 < data.count else { return }
                let part = try parser.parse(data: data)
                multiPart.append(part)
                
                log.debug("\nparsed part header: \(part.header), size: \(data.count)\n"
                    + "data: \(String(data: part.body, encoding: .utf8) ?? "<<recv data cannot be converted to string>>")")
            }
        } catch {
            log.error("parser error: \(error)\n"
                + "data:\n\(String(data: self.data, encoding: .ascii) ?? "<<recv data cannot be converted to string>>")")
        }
        self.data = self.data.subdata(in: size..<self.data.count)
        
        return multiPart
    }
}
