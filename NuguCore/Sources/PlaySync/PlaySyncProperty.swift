//
//  PlaySyncProperty.swift
//  NuguCore
//
//  Created by MinChul Lee on 2020/03/03.
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

/// <#Description#>
public struct PlaySyncProperty {
    /// <#Description#>
    public let layerType: LayerType
    /// <#Description#>
    public let contextType: ContextType
    
    /// <#Description#>
    /// - Parameters:
    ///   - layerType: <#layerType description#>
    ///   - contextType: <#contextType description#>
    public init(layerType: LayerType, contextType: ContextType) {
        self.layerType = layerType
        self.contextType = contextType
    }
    
    /// <#Description#>
    public enum LayerType: String, Codable {
        case info = "INFO"
        case media = "MEDIA"
        case call = "CALL"
        case alert = "ALERT"
        case overlay = "OVERLAY"
        case asr = "ASR"
    }
    
    /// <#Description#>
    public enum ContextType: String {
        case sound
        case display
    }
}

// MARK: - Hashable

/// :nodoc:
extension PlaySyncProperty: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(layerType.hashValue)
        hasher.combine(contextType.hashValue)
    }
}

// MARK: - CustomStringConvertible

/// :nodoc:
extension PlaySyncProperty.LayerType: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}

/// :nodoc:
extension PlaySyncProperty.ContextType: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}

/// :nodoc:
extension PlaySyncProperty: CustomStringConvertible {
    public var description: String {
        return "Layer: \(layerType).\(contextType)"
    }
}
