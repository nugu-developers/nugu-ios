//
//  NuguApiRequest.swift
//  NuguInterface
//
//  Created by MinChul Lee on 2019/12/10.
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

public struct NuguApiRequest {
    public let path: String
    public let method: String
    public let header: [String: String]
    public let bodyData: Data
    public let queryItems: [String: String?]
    
    public init(path: String, method: String, header: [String: String], bodyData: Data, queryItems: [String: String?]) {
        self.path = path
        self.method = method
        self.header = header
        self.bodyData = bodyData
        self.queryItems = queryItems
    }
}
