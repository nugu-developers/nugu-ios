//
//  ShiftingData.swift
//  KeenSense
//
//  Created by DCs-OfficeMBP on 29/05/2019.
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
 Automated Shifting Data.
 This Data Structure size is limited.
 When the new data comes, calculate total data size to be then drops oldest bytes.
 It can be usefull for keeping latest certain byte size of data.
 */
class ShiftingData {
    private let capacity: Int
    private var internalData = Data()
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    public var count: Int {
        return internalData.count
    }
    
    /**
     Make some space for appending
     */
    private func adjustSize(by neededSize: Int) {
        let availableLength = capacity - (internalData.count + neededSize)
        if availableLength < 0 {
            let neededLength = abs(availableLength)
            internalData = internalData.subdata(in: neededLength..<internalData.count)
        }
    }
    
    /**
     Be ware to lose oldest data.
     This Data Structure keeps Certain size of latest bytes.
     */
    func append(_ other: Data) {
        adjustSize(by: other.count)
        internalData.append(other)
    }
    
    func subdata(in range: Range<Data.Index>) -> Data {
        return internalData.subdata(in: range)
    }
    
    func removeAll() {
        internalData.removeAll()
    }
    
    func write(to: URL) throws {
        try internalData.write(to: to)
    }
}
