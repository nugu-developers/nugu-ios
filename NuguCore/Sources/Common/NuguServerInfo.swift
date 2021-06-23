//
//  NuguServerInfo.swift
//  NuguCore
//
//  Created by childc on 2019/11/20.
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

/// Manage the device-gateway server address.
public enum NuguServerInfo {
    /// The resource server address.
    public static var l4SwitchAddress: String?
    /// The registry server address.
    public static var registryServerAddress: String?
}
