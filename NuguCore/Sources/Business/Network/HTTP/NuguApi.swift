//
//  NuguApi.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 08/07/2019.
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

public enum NuguApi {
    case policy
    case directives
    case event
    case eventAttachment
    case ping
    case crashReport
}

extension NuguApi: CustomStringConvertible {
    public var description: String {
        switch self {
        case .policy:
            return "policy"
        case .directives:
            return "directives"
        case .event:
            return "event"
        case .eventAttachment:
            return "attachment for event"
        case .ping:
            return "ping"
        case .crashReport:
            return "crash report"
        }
    }
}

public extension NuguApi {
    var path: String {
        switch self {
        case .policy:
            return "policies"
        case .event:
            return "event"
        case .eventAttachment:
            return "event-attachment"
        case .directives:
            return "directives"
        case .ping:
            return "ping"
        case .crashReport:
            return "crash"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .event,
             .eventAttachment,
             .crashReport:
            return .post
        case .policy,
             .directives,
             .ping:
            return .get
        }
    }
    
    var header: [String: String] {
        switch self {
        case .policy:
            return [
                "Authorization": AuthorizationManager.shared.authorizationPayload?.authorization ?? ""
            ]
        case .directives:
            return [
                "Authorization": AuthorizationManager.shared.authorizationPayload?.authorization ?? "",
                "User-Agent": NetworkConst.userAgent
            ]
        case .event:
             return [
                "Authorization": AuthorizationManager.shared.authorizationPayload?.authorization ?? "",
                "User-Agent": NetworkConst.userAgent,
                "Content-Type": "application/json"
                ]
        case .eventAttachment:
            return [
                "Authorization": AuthorizationManager.shared.authorizationPayload?.authorization ?? "",
                "User-Agent": NetworkConst.userAgent,
                "Content-Type": "application/octet-stream"
            ]
        case .ping:
            return [
                "Authorization": AuthorizationManager.shared.authorizationPayload?.authorization ?? "",
                "User-Agent": NetworkConst.userAgent
            ]
        case .crashReport:
            return [
                "Authorization": AuthorizationManager.shared.authorizationPayload?.authorization ?? "",
                "User-Agent": NetworkConst.userAgent,
                "Content-Type": "application/json"
            ]
        }
    }
}
