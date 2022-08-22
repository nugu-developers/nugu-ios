//
//  MockTextAgent.swift
//  NuguTests
//
//  Created by jaycesub on 2022/08/18.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
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

import NuguAgents
import NuguCore

class MockTextAgent: TextAgentProtocol {
    var delegate: TextAgentDelegate?
    
    var capabilityAgentProperty: CapabilityAgentProperty = .init(category: .text, version: "")
    
    var contextInfoProvider: ContextInfoProviderType = { _ in }
    
    var receivedText: String?
    var receivedToken: String?
    var receivedType: TextAgentRequestType?
    
    func clearAttributes() {
        // Nothing to do.
    }
    
    func requestTextInput(text: String, token: String?, source: String?, requestType: TextAgentRequestType, completion: ((StreamDataState) -> Void)?) -> String {
        receivedText = text
        receivedToken = token
        receivedType = requestType
        completion?(.finished)
        return ""
    }
}
