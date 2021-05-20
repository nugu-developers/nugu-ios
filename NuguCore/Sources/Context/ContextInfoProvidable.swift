//
//  ContextInfoProvidable.swift
//  NuguCore
//
//  Created by MinChul Lee on 25/04/2019.
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

public typealias ContextInfoProviderType = (_ completion: @escaping (ContextInfo?) -> Void) -> Void

/// ContextInfoProvidable may be capability agent whose context needs to be sent to the server.
public protocol ContextInfoProvidable: AnyObject {
     /// A request to provide the context.
     ///
     /// It should perform minimum processing and return quickly
    var contextInfoProvider: ContextInfoProviderType { get }
}
