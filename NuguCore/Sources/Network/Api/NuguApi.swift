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

enum NuguApi {
    case policy
    case directives
    case events
    case eventAttachment
    case ping
}

extension NuguApi: CustomStringConvertible {
    var description: String {
        switch self {
        case .policy:
            return "policy"
        case .directives:
            return "directives"
        case .events:
            return "events"
        case .eventAttachment:
            return "attachment for event"
        case .ping:
            return "ping"
        }
    }
}

extension NuguApi {
    var version: String {
        switch self {
        case .events,
             .directives,
             .ping:
            return "v2"
        default:
            return "v1"
        }
    }

    var path: String {
        switch self {
        case .policy:
            return "policies"
        case .events:
            return "events"
        case .eventAttachment:
            return "event-attachment"
        case .directives:
            return "directives"
        case .ping:
            return "ping"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .events,
             .eventAttachment:
            return .post
        case .policy,
             .directives,
             .ping:
            return .get
        }
    }
    
    var header: [String: String]? {
        guard let token = AuthorizationStore.shared.authorizationToken else {
            return nil
        }
        
        switch self {
        case .policy:
            return [
                "Authorization": token
            ]
        case .directives:
            return [
                "Authorization": token,
                "User-Agent": NetworkConst.userAgent
            ]
        case .events:
             return [
                "Authorization": token,
                "User-Agent": NetworkConst.userAgent
                ]
        case .eventAttachment:
            return [
                "Authorization": token,
                "User-Agent": NetworkConst.userAgent,
                "Content-Type": "audio/speex"
            ]
        case .ping:
            return [
                "Authorization": token,
                "User-Agent": NetworkConst.userAgent
            ]
        }
    }
}

extension NuguApi {
    func uri(baseUrl: String) -> String {
        [baseUrl, version, path].joined(separator: "/")
    }
}
