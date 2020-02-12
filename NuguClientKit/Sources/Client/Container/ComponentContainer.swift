//
//  ComponentContainer.swift
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

import NuguCore

public final class ComponentContainer {
    private var components: [ComponentKey: Any]
    
    /**
     To put component into the container
     - parameter protocol: representative name.
     - parameter option: If you want to register multiple instances of concreate class, you should set this argument to .all for distinction.
     - parameter factory: component factory
     */
    public func register<Component>(_ protocol: Any.Type, option: ComponentKey.Option = .representative, factory: @escaping (ComponentResolver) -> Component) {
        let key = ComponentKey(protocolType: `protocol`.self, concreateType: Component.self, option: option)
        let component = factory(self)
        components[key] = component
    }
    
    private init(components: [ComponentKey: Any]) {
        self.components = components
    }
    
    public init() {
        components = [ComponentKey: Any]()
    }
    
    public func union(_ other: ComponentContainer) -> ComponentContainer {
        var unionComponents = [ComponentKey: Any]()
        unionComponents.merge(components, uniquingKeysWith: { $1 })
        unionComponents.merge(other.components, uniquingKeysWith: { $1 })
        
        return ComponentContainer(components: unionComponents)
    }
    
    public func subtract(_ other: ComponentContainer) -> ComponentContainer {
        var subComponents = [ComponentKey: Any]()
        subComponents.merge(components, uniquingKeysWith: { $1 })
        
        for key in other.components.keys {
            subComponents.removeValue(forKey: key)
        }
        
        return ComponentContainer(components: subComponents)
    }
}

extension ComponentContainer: ComponentResolver {
    public func resolve<Component, Concreate>(_ protocol: Component.Type, concreateType: Concreate.Type?, option: ComponentKey.Option) -> Concreate? {
        let key = ComponentKey(protocolType: `protocol`.self, concreateType: concreateType, option: option)
        return components[key] as? Concreate
    }
}
