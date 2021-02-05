//
//  Session.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/05/28.
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

/// <#Description#>
public struct Session: Equatable {
    /// <#Description#>
    public let sessionId: String
    /// <#Description#>
    public let dialogRequestId: String
    /// <#Description#>
    public let playServiceId: String
    
    /// <#Description#>
    /// - Parameters:
    ///   - sessionId: <#sessionId description#>
    ///   - dialogRequestId: <#dialogRequestId description#>
    ///   - playServiceId: The unique identifier to specify play service.
    public init(sessionId: String, dialogRequestId: String, playServiceId: String) {
        self.sessionId = sessionId
        self.dialogRequestId = dialogRequestId
        self.playServiceId = playServiceId
    }
}

// MARK: - CustomStringConvertible

/// :nodoc:
extension Session: CustomStringConvertible {
    public var description: String {
        return "\(dialogRequestId)-\(sessionId)"
    }
}
