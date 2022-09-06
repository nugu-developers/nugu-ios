//
//  DialogAttributeStore.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/05/28.
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

import NuguUtils
import NattyLog

public final class DialogAttributeStore: DialogAttributeStoreable {
    @Atomic private var attributeDic = [String: AnyHashable]() {
        didSet {
            log.debug("attributes changed: \(attributeDic)")
            post(NuguAgentNotification.DialogAttribute(attribute: attributeDic))
        }
    }
    
    public init() {}
    
    public func setAttributes(_ attributes: [String: AnyHashable], key: String) {
        _attributeDic.mutate { $0[key] = attributes }
    }
    
    public func requestAttributes(key: String? = nil) -> [String: AnyHashable]? {
        var lastingAttributes: [String: AnyHashable]? {
            guard let key = attributeDic.keys.first else {
                return nil
            }
            
            return attributeDic[key] as? [String: AnyHashable]
        }
        
        guard let key = key else {
            return lastingAttributes
        }

        let specificAttributes = attributeDic[key] as? [String: AnyHashable]
        return specificAttributes ?? lastingAttributes
    }
    
    public func getAttributes(key: String) -> [String: AnyHashable]? {
        attributeDic[key] as? [String: AnyHashable]
    }
    
    public func removeAttributes(key: String) {
        _attributeDic.mutate { $0[key] = nil }
    }
    
    public func removeAllAttributes() {
        _attributeDic.mutate { $0.removeAll() }
    }
}

public extension NuguAgentNotification {
    struct DialogAttribute: TypedNotification {
        public static let name: Notification.Name = .dialogAttributeDidChange
        public let attribute: [String: AnyHashable]?
        
        public static func make(from: [String: Any]) -> NuguAgentNotification.DialogAttribute? {
            guard let attribute = from["attribute"] as? [String: AnyHashable] else { return nil }
            return DialogAttribute(attribute: attribute)
        }
    }
}

extension Notification.Name {
    static let dialogAttributeDidChange = Notification.Name("com.sktelecom.romaine.notification.name.dialog_attribute_did_chage")
}
