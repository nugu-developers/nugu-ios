//
//  SharedBufferIndex.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 02/05/2019.
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

struct SharedBufferIndex {
    private var internalValue: Int = 0
    private let bufferSize: Int
    var value: Int {
        get {
            return internalValue
        }
        
        set {
            internalValue = adjustIndex(newValue)
        }
    }
    
    init(bufferSize: Int) {
        self.bufferSize = bufferSize
    }
    
    func adjustIndex(_ index: Int) -> Int {
        return index % bufferSize
    }
    
    static func < (lhs: SharedBufferIndex, rhs: SharedBufferIndex) -> Bool {
        switch (lhs.value, rhs.value) {
        case (0, 0):
            return false
        case (_, 0):
            // 0 is the Biggest number in the Circular index world.
            return true
        default:
            return lhs.value < rhs.value
        }
    }
    
    static func > (lhs: SharedBufferIndex, rhs: SharedBufferIndex) -> Bool {
        switch (lhs.value, rhs.value) {
        case (0, 0):
            return false
        case (0, _):
            // 0 is the Biggest number in the Circular index world.
            return true
        default:
            return lhs.value > rhs.value
        }
    }
    
    static func == (lhs: SharedBufferIndex, rhs: SharedBufferIndex) -> Bool {
        return lhs.value == rhs.value
    }
    
    static func != (lhs: SharedBufferIndex, rhs: SharedBufferIndex) -> Bool {
        return lhs.value != rhs.value
    }
    
    static func += (lhs: inout SharedBufferIndex, rhs: SharedBufferIndex) {
        lhs.value += rhs.value
    }
    
    static func -= (lhs: inout SharedBufferIndex, rhs: SharedBufferIndex) {
        lhs.value -= rhs.value
    }
    
    static func == (lhs: SharedBufferIndex, rhs: Int) -> Bool {
        return lhs.value == rhs
    }
    
    static func != (lhs: SharedBufferIndex, rhs: Int) -> Bool {
        return lhs.value != rhs
    }
    
    static func += (lhs: inout SharedBufferIndex, rhs: Int) {
        lhs.value += rhs
    }
    
    static func -= (lhs: inout SharedBufferIndex, rhs: Int) {
        lhs.value -= rhs
    }
    
    static func == (lhs: Int, rhs: SharedBufferIndex) -> Bool {
        return lhs == rhs.value
    }
    
    static func != (lhs: Int, rhs: SharedBufferIndex) -> Bool {
        return lhs != rhs.value
    }
    
    static func += (lhs: inout Int, rhs: SharedBufferIndex) {
        lhs += rhs.value
    }
    
    static func -= (lhs: inout Int, rhs: SharedBufferIndex) {
        lhs -= rhs.value
    }
}
