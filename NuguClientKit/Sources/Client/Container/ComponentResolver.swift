//
//  ComponentResolver.swift
//  NuguClientKit
//
//  Created by childc on 2020/01/09.
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

public protocol ComponentResolver {
    /**
    To get component.
    - parameter protocol: representative name
    - parameter concreateType: If you registered using options(.all), You should give certain concreate type for distinction
    - parameter option: option for distinction. If you set this argument as .representative, concreateType will be ignored though you provide certain concreate type.
    */
    func resolve<Component, Concreate>(_ protocol: Component.Type, concreateType: Concreate.Type?, option: ComponentKey.Option) -> Concreate?
}

public extension ComponentResolver {
    func resolve<Component>(_ componentType: Component.Type) -> Component? {
        return resolve(componentType, concreateType: nil, option: .representative)
    }
    
    func resolve<Component, Concreate>(_ componentType: Component.Type, concreateType: Concreate.Type?) -> Concreate? {
        return resolve(componentType, concreateType: concreateType, option: concreateType == nil ? .representative : .all)
    }
}
