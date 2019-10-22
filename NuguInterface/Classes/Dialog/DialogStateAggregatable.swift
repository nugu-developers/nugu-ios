//
//  DialogStateAggregatable.swift
//  NuguInterface
//
//  Created by MinChul Lee on 19/04/2019.
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

/// DialogStateAggregator aggregate several components state into one.
public protocol DialogStateAggregatable:
ASRAgentDelegate, TTSAgentDelegate, TextAgentDelegate {
    var expectSpeech: ASRExpectSpeech? { get set }
        
    /// Adds a delegate to be notified of DialogStateAggregator state changes.
    /// - Parameter delegate: The object to add.
    func add(delegate: DialogStateDelegate)
    
    /// Removes a delegate from DialogStateAggregator.
    /// - Parameter delegate: The object to remove.
    func remove(delegate: DialogStateDelegate)
}
