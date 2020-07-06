//
//  MediaPlayerAgent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/07/06.
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

import NuguCore

class MediaPlayerAgent: MediaPlayerAgentProtocol {
    var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .mediaPlayer, version: "1.0")
    
    public weak var delegate: MediaPlayerAgentDelegate?
    
    private let mediaPlayerDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.mediaplayer_agent", qos: .userInitiated)
    
    public init(contextManager: ContextManageable) {
        contextManager.add(delegate: self)
    }
}

// MARK: - ContextInfoDelegate

extension MediaPlayerAgent: ContextInfoDelegate {
    func contextInfoRequestContext(completion: @escaping (ContextInfo?) -> Void) {
        let payload: [String: AnyHashable?] = [
            "version": capabilityAgentProperty.version
        ]
        
        completion(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
    }
}
