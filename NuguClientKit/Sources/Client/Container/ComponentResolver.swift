//
//  ComponentResolver.swift
//  NuguClientKit
//
//  Created by childc on 2020/01/09.
//

import Foundation

public protocol ComponentResolver {
    func resolve<Component, Concreate>(_ protocol: Component.Type, concreateType: Concreate.Type?, option: ComponentKey.Option) -> Concreate?
}

extension ComponentResolver {
    func resolve<Component>(_ componentType: Component.Type) -> Component? {
        return resolve(componentType, concreateType: nil, option: .representative)
    }
    
    func resolve<Component, Concreate>(_ componentType: Component.Type, concreateType: Concreate.Type?) -> Concreate? {
        return resolve(componentType, concreateType: concreateType, option: concreateType == nil ? .representative : .all)
    }
}
