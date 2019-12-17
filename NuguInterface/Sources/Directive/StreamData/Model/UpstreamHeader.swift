//
//  UpstreamHeader.swift
//  NuguInterface
//
//  Created by MinChul Lee on 22/05/2019.
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

/// <#Description#>
public struct UpstreamHeader {
    public let namespace: String
    public let name: String
    public let version: String
    public let dialogRequestId: String
    public let messageId: String
    
    /// <#Description#>
    /// - Parameter namespace: <#namespace description#>
    /// - Parameter name: <#name description#>
    /// - Parameter version: <#version description#>
    /// - Parameter dialogRequestId: <#dialogRequestId description#>
    public init(namespace: String, name: String, version: String, dialogRequestId: String) {
        self.namespace = namespace
        self.name = name
        self.version = version
        self.dialogRequestId = dialogRequestId
        // 64bit (8bytes) base16 hexa string(string length is 16)
        self.messageId = String(format: "%llx", UInt64.random(in: 0..<UInt64.max))
    }
}
    
