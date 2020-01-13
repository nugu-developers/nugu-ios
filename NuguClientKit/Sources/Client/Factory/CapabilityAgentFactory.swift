//
//  CapabilityAgentFactory.swift
//  NuguClientKit
//
//  Created by yonghoonKwon on 2019/12/11.
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

import NuguInterface

/// <#Description#>
public protocol CapabilityAgentFactory {
    
    /// <#Description#>
    /// - Parameter container: <#container description#>
    static func makeASRAgent(resolver: ComponentResolver) -> ASRAgentProtocol?
    
    /// <#Description#>
    /// - Parameter container: <#container description#>
    static func makeTTSAgent(resolver: ComponentResolver) -> TTSAgentProtocol?
    
    /// <#Description#>
    /// - Parameter container: <#container description#>
    static func makeAudioPlayerAgent(resolver: ComponentResolver) -> AudioPlayerAgentProtocol?
    
    /// <#Description#>
    /// - Parameter container: <#container description#>
    static func makeDisplayAgent(resolver: ComponentResolver) -> DisplayAgentProtocol?
    
    /// <#Description#>
    /// - Parameter container: <#container description#>
    static func makeTextAgent(resolver: ComponentResolver) -> TextAgentProtocol?
    
    /// <#Description#>
    /// - Parameter container: <#container description#>
    static func makeExtensionAgent(resolver: ComponentResolver) -> ExtensionAgentProtocol?
    
    /// <#Description#>
    /// - Parameter container: <#container description#>
    static func makeLocationAgent(resolver: ComponentResolver) -> LocationAgentProtocol?
}
