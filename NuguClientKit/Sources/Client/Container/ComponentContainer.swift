//
//  ComponentContainer.swift
//  NuguClientKit
//
//  Created by childc on 2020/01/09.
//

import Foundation

public final class ComponentContainer {
    private var components = [ComponentKey: Any]()
    
    public func register<Component>(_ protocol: Any.Type, option: ComponentKey.Option = .representative, factory: @escaping (ComponentResolver) -> Component) {
        let key = ComponentKey(protocolType: `protocol`.self, concreateType: Component.self, option: option)
        let component = factory(self)
        components[key] = component
    }
}

extension ComponentContainer: ComponentResolver {
    public func resolve<Component, Concreate>(_ protocol: Component.Type, concreateType: Concreate.Type?, option: ComponentKey.Option) -> Concreate? {
        let key = ComponentKey(protocolType: `protocol`.self, concreateType: concreateType, option: option)
        return components[key] as? Concreate
    }
}
