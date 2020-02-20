//
//  FocusChannelInfo.swift
//  NuguCore
//
//  Created by MinChul Lee on 18/05/2019.
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

struct FocusChannelInfo {
    weak var delegate: FocusChannelDelegate?
    let focusState: FocusState
}

// MARK: - Equatable

extension FocusChannelInfo: Equatable {
    static func == (lhs: FocusChannelInfo, rhs: FocusChannelInfo) -> Bool {
        lhs.delegate === rhs.delegate
    }
}

// MARK: - Array + FocusChannelInfo

extension Array where Element == FocusChannelInfo {
    /// Replaces and returns the original element
    mutating func replace(info: FocusChannelInfo) -> FocusChannelInfo? {
        removeAll { $0.delegate == nil }
        if let index = firstIndex(of: info) {
            let originalInfo = remove(at: index)
            insert(info, at: 0)
            return originalInfo
        }
        return nil
    }
    
    /// Removes and returns the original element
    @discardableResult mutating func remove(delegate: FocusChannelDelegate) -> FocusChannelInfo? {
        removeAll { $0.delegate == nil }
        if let info = object(forDelegate: delegate),
            let index = firstIndex(of: info) {
            return remove(at: index)
        }
        return nil
    }
    
    /// Returns the element for delegate
    func object(forDelegate delegate: FocusChannelDelegate) -> FocusChannelInfo? {
        first { $0.delegate === delegate }
    }
}
