//
//  AlertsRepeat.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2021/03/05.
//  Copyright (c) 2021 SK Telecom Co., Ltd. All rights reserved.
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

import Foundation

public struct AlertsRepeat: Codable {
    public let type: String
    public let daysOfWeek: [String]?
    public let skippable: Skippable?
    
    public init(
        type: String,
        daysOfWeek: [String]?,
        skippable: Skippable?
    ) {
        self.type = type
        self.daysOfWeek = daysOfWeek
        self.skippable = skippable
    }
}

public extension AlertsRepeat {
    struct Skippable: Codable {
        public let skipHolidays: Bool
    }
}
