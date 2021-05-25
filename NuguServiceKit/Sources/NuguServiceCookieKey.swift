//
//  NuguServiceCookieKey.swift
//  NuguServiceKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2021/05/04.
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
//

public struct NuguServiceCookieKey: RawRepresentable, Equatable, Hashable {
    public private(set) var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension NuguServiceCookieKey {
    static let theme = NuguServiceCookieKey("Theme")
    static let deviceUniqueId = NuguServiceCookieKey("Device-Unique-Id")
}
