//
//  ExtensionAgentProtocol.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 25/07/2019.
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

import NuguCore

/// `ExtensionAgent` handles directives that not defined by other capability-agents
public protocol ExtensionAgentProtocol: CapabilityAgentable {
    /// The object that acts as the delegate of `ExtensionAgent`
    var delegate: ExtensionAgentDelegate? { get set }
    
    /// Send event to specific play with custom data.
    ///
    /// [JSONSerialization.isValidJSONObject]: apple-reference-documentation://hsLgkBvV03
    /// - Parameters:
    ///   - data: Custom data as a Dictionary. Should be available converting JSON format.
    ///           see [JSONSerialization.isValidJSONObject].
    ///   - playServiceId: The unique identifier to specify play service.
    ///   - completion: The completion handler to call when the request is complete.
    /// - Returns: The dialogRequestId for request.
    @discardableResult func requestCommand(data: [String: AnyHashable], playServiceId: String, completion: ((StreamDataState) -> Void)?) -> String
}

// MARK: - Default

public extension ExtensionAgentProtocol {
    @discardableResult func requestCommand(data: [String: AnyHashable], playServiceId: String) -> String {
        return requestCommand(data: data, playServiceId: playServiceId, completion: nil)
    }
}
