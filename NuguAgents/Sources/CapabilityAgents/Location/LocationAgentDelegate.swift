//
//  LocationAgentDelegate.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2019/10/30.
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

/// The methods that you use to receive location information from an associated `LocationAgent` object.
public protocol LocationAgentDelegate: AnyObject {
    
    /// It called when need location information for using nugu service.
    ///
    /// It is used as `ContextInfo`, thus must be get `LocationInfo` quickly and synchronous.
    /// Mostly used when every a request through `ASRAgent` or `TextAgent`.
    /// Best to use cached value or constant value when possible.
    func locationAgentRequestLocationInfo() -> LocationInfo?
}
