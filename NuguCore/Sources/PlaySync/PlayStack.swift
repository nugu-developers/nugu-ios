//
//  PlayStack.swift
//  NuguCore
//
//  Created by MinChul Lee on 2020/03/11.
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

struct PlayStack {
    private var stack = [(property: PlaySyncProperty, info: PlaySyncInfo)]()
    
    var multiLayerSynced: Bool {
        stack
            .map { $0.property.layerType }
            .reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
            .count > 1
    }
    
    var playServiceIds: [String] {
        stack
            .compactMap { $0.info.playStackServiceId }
            .reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
    }
    
    subscript(property: PlaySyncProperty) -> PlaySyncInfo? {
        get {
            return stack.first { $0.property == property }?.info
        }
        set {
            stack.removeAll { $0.property == property }
            if let info = newValue {
                stack.insert((property, info), at: 0)
            }
            log.debug(stack)
        }
    }
    
    func filter(isIncluded predict: ((property: PlaySyncProperty, info: PlaySyncInfo)) -> Bool) -> [(property: PlaySyncProperty, info: PlaySyncInfo)] {
        return stack.filter(predict)
    }
}
