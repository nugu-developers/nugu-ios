//
//  SoundAgent.swift
//  NuguCore
//
//  Created by yonghoonKwon on 2019/11/14.
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

import NuguInterface

final public class SoundAgent: SoundAgentProtocol {
    public var capabilityAgentProperty = CapabilityAgentProperty(category: .sound, version: "1.0")
    
    public var messageSender: MessageSendable!
    
    public weak var delegate: SoundAgentDelegate?
    
    public init() {
        log.info("")
    }
    
    deinit {
        log.info("")
    }
}

// MARK: - ContextInfoDelegate

extension SoundAgent: ContextInfoDelegate {
    public func contextInfoRequestContext() -> ContextInfo? {
        let payload: [String: Any] = [:]
        
        return ContextInfo(
            contextType: .capability,
            name: capabilityAgentProperty.name,
            payload: payload
        )
    }
}

// MARK: - HandleDirectiveDelegate

extension SoundAgent: HandleDirectiveDelegate {
    public func handleDirectiveTypeInfos() -> DirectiveTypeInfos {
        return DirectiveTypeInfo.allDictionaryCases
    }
    
    public func handleDirective(
        _ directive: DirectiveProtocol,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self) else {
            completionHandler(.failure(HandleDirectiveError.handleDirectiveError(message: "Unknown directive")))
            return
        }
        
        switch directiveTypeInfo {
        case .beep:
            guard let data = directive.payload.data(using: .utf8) else {
                completionHandler(.failure(HandleDirectiveError.handleDirectiveError(message: "Invalid payload")))
                return
            }
            
            let beep: SoundAgentBeep
            do {
                beep = try JSONDecoder().decode(SoundAgentBeep.self, from: data)
            } catch {
                completionHandler(.failure(error))
                return
            }
            
            delegate?.soundAgentDidRequestToPlay(beep: beep)
            completionHandler(.success(()))
        }
    }
}
