//
//  DisplayTemplate.swift
//  NuguInterface
//
//  Created by MinChul Lee on 17/05/2019.
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

public struct DisplayTemplate {
    public let type: String
    public let payload: String
    public let templateId: String
    public let dialogRequestId: String
    public let token: String
    public let playServiceId: String
    public let playStackServiceId: String?
    public let duration: Duration
    
    public init(
        type: String,
        payload: String,
        templateId: String,
        dialogRequestId: String,
        token: String,
        playServiceId: String,
        playStackServiceId: String?,
        duration: Duration?
    ) {
        self.type = type
        self.payload = payload
        self.templateId = templateId
        self.dialogRequestId = dialogRequestId
        self.token = token
        self.playServiceId = playServiceId
        self.playStackServiceId = playStackServiceId
        self.duration = duration ?? .short
    }
}

public extension DisplayTemplate {
    // TODO: PlaySyncDuration과 같음.
    enum Duration: String {
        /// <#Description#>
        case short = "SHORT"
        /// <#Description#>
        case mid = "MID"
        /// <#Description#>
        case long = "LONG"
        /// <#Description#>
        case longest = "LONGEST"
    }
}

public extension DisplayTemplate.Duration {
    var time: DispatchTimeInterval {
        switch self {
        case .short: return .seconds(7)
        case .mid: return .seconds(15)
        case .long: return .seconds(30)
        case .longest: return .seconds(60 * 10)
        }
    }
}

public extension DisplayTemplate {
    /// An enum class used to specify the reason to clear the template.
    enum ClearReason {
        /// Clear request due to `DisplayTemplate.Duration`.
        ///
        /// Application can decide whether or not to clear the template.
        case timer
        /// Clear request due to directive.
        ///
        /// Application must clear the template.
        case directive
    }
}
