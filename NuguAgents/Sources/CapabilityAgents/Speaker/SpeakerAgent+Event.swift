//
//  SpeakerAgent+Event.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 10/06/2019.
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

// MARK: - CapabilityEventAgentable

extension SpeakerAgent {
    public struct Event {
        let typeInfo: TypeInfo
        let volumes: [SpeakerMuteInfo.Volume]
        let playServiceId: String
        
        public enum TypeInfo {
            case setMuteSucceeded
            case setMuteFailed
        }
    }
}

// MARK: - Eventable

extension SpeakerAgent.Event: Eventable {
    public var payload: [String: Any] {
        return [
            "playServiceId": playServiceId,
            "volumes": volumes.values
        ]
    }
    
    public var name: String {
        switch typeInfo {
        case .setMuteSucceeded:
            return "SetMuteSucceeded"
        case .setMuteFailed:
            return "SetMuteFailed"
        }
    }
}

// MARK: - Equatable

extension SpeakerAgent.Event.TypeInfo: Equatable {}
extension SpeakerAgent.Event: Equatable {}
