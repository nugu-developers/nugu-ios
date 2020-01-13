//
//  ComponentKey.swift
//  NuguClientKit
//
//  Created by childc on 2020/01/09.
//

import Foundation

public struct ComponentKey {
    public enum Option {
        case all
        case representative
    }
    
    public var protocolType: Any.Type
    public var concreateType: Any.Type?
    public var option: Option
}

extension ComponentKey: Hashable {
    public static func == (lhs: ComponentKey, rhs: ComponentKey) -> Bool {
        return lhs.protocolType == rhs.protocolType
    }
    
    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(protocolType).hash(into: &hasher)
        
        if option == .all,
            concreateType != nil {
            ObjectIdentifier(concreateType!).hash(into: &hasher)
        }
    }
}
