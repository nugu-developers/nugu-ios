//
//  EventSenderError.swift
//  NuguCore
//
//  Created by childc on 2020/03/04.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

import NuguUtils

/// An error that occurs while sending the event.
public enum EventSenderError: Error, CustomStringConvertible {
    /// Requested to send an event with a duplicate ID.
    case requestMultipleEvents
    /// Requested to send an attachment without event.
    case noEventRequested
    /// An error occurred while executing `OutputStream.write`.
    case streamBlocked
    /// An error occurred while executing `OutputStream.write`.
    case streamError(_ streamError: Error)
    /// An error occurred while executing `OutputStream.write`.
    case cannotBindMemory
    
    public var description: String {
        switch self {
        case .requestMultipleEvents:
            return "Request multiple events"
        case .noEventRequested:
            return "No event Requested before"
        case .streamBlocked:
            return "Stream is blocked"
        case .streamError(let error):
            return "Stream error: \(error)"
        case .cannotBindMemory:
            return "Cannot bind memory"
        }
    }
}

extension EventSenderError: CodableError {
    enum CodingKeys: CodingKey {
        case code
        case associatedValue
    }
    
    public var code: Int {
        switch self {
        case .requestMultipleEvents:
            return 0
        case .noEventRequested:
            return 1
        case .streamBlocked:
            return 2
        case .streamError:
            return 3
        case .cannotBindMemory:
            return 4
        }
    }
    
    public var name: String {
        return self.description
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let code = try container.decode(CodableError.Code.self, forKey: .code)
        switch code {
        case 0:
            self = .requestMultipleEvents
        case 1:
            self = .noEventRequested
        case 2:
            self = .streamBlocked
        case 3:
            self = .streamError(try container.decode(NSError.self, forKey: .associatedValue))
        case 4:
            self = .cannotBindMemory
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unmatched case"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.code, forKey: .code)
        
        if case let .streamError(error) = self {
            try container.encode(error as NSError, forKey: .associatedValue)
        }
    }
}
