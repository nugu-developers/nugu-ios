//
//  ImageAgentProtocol.swift
//  NuguAgents
//
//  Created by jayceSub on 2023/05/10.
//  Copyright (c) 2023 SK Telecom Co., Ltd. All rights reserved.
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

import Foundation

import NuguCore

public protocol ImageAgentProtocol: CapabilityAgentable {
    @discardableResult func requestSendImage(
        _ image: Data,
        service: [String: AnyHashable]?,
        completion: ((StreamDataState) -> Void)?
    ) -> String
    
    @discardableResult func requestSendImage(
        _ image: Data,
        service: [String: AnyHashable]?,
        completion: ((StreamDataState) -> Void)?
    ) -> EventIdentifier
}

public extension ImageAgentProtocol {
    @discardableResult func requestSendImage(
        _ image: Data,
        service: [String: AnyHashable]? = nil,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        requestSendImage(image, service: service, completion: completion).dialogRequestId
    }
}
