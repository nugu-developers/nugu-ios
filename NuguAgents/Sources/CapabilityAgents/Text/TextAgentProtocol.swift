//
//  TextAgentProtocol.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 17/06/2019.
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

/// `TextAgent` is needed to send event-based text recognition.
public protocol TextAgentProtocol: CapabilityAgentable {
    /// The object that acts as the delegate of `TextAgent`
    var delegate: TextAgentDelegate? { get set }
    
    /// Send event that needs a text-based recognition
    /// - Parameters:
    ///   - text: The `text` to be recognized
    ///   - completion: The completion handler to call when the request is complete.
    /// - Returns: The dialogRequestId for request.
    @discardableResult func requestTextInput(
        text: String,
        token: String?,
        source: TextInputSource?,
        requestType: TextAgentRequestType,
        completion: ((StreamDataState) -> Void)?
    ) -> String
}

// MARK: - Default

public extension TextAgentProtocol {
    @discardableResult func requestTextInput(
        text: String,
        token: String? = nil,
        source: TextInputSource? = nil,
        requestType: TextAgentRequestType
    ) -> String {
        return requestTextInput(
            text: text,
            token: token,
            source: source,
            requestType: requestType,
            completion: nil
        )
    }
    
    @discardableResult func requestTextInput(
        text: String,
        token: String? = nil,
        source: TextInputSource? = nil,
        requestType: TextAgentRequestType,
        completion: ((StreamDataState) -> Void)?
    ) -> String {
        return requestTextInput(
            text: text,
            token: token,
            source: source,
            requestType: requestType,
            completion: completion
        )
    }
}
