//
//  ContextInfo.swift
//  NuguCore
//
//  Created by MinChul Lee on 28/05/2019.
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

/// The context of the ContextInfoDelegate
public struct ContextInfo {
    /// <#Description#>
    public let contextType: ContextType
    
    /// The name of the ProvideContextDelegate.
    public let name: String
    
    /// The state of the ProvideContextDelegate.
    public let payload: AnyHashable
    
    /// <#Description#>
    /// - Parameters:
    ///   - contextType: <#contextType description#>
    ///   - name: <#name description#>
    ///   - payload: <#payload description#>
    public init(contextType: ContextType, name: String, payload: AnyHashable) {
        self.contextType = contextType
        self.name = name
        self.payload = payload
    }
}
