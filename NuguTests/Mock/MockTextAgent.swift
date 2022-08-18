//
//  MockTextAgent.swift
//  NuguTests
//
//  Created by 신정섭님/A.출시 on 2022/08/18.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
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
