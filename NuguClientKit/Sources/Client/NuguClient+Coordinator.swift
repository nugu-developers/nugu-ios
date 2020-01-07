//
//  NuguClient+Coordinator.swift
//  NuguClientKit
//
//  Created by DCs-OfficeMBP on 20/06/2019.
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
import NuguCore

// MARK: - Coordinator

extension NuguClient {
    func setupDependencies() {
        // Setup managers
        networkManager.add(receiveMessageDelegate: streamDataRouter)
        streamDataRouter.add(delegate: directiveSequencer)
        contextManager.add(provideContextDelegate: playSyncManager)
        
        setupAudioStreamDependency()
        setupWakeUpDetectorDependency()
    }
}

// MARK: - Core

extension NuguClient {
    func setupAudioStreamDependency() {
        guard let audioStream = sharedAudioStream as? AudioStream else { return }
        
        audioStream.delegate = self
    }
    
    func setupWakeUpDetectorDependency() {
        guard let wakeUpDetector = wakeUpDetector else { return }
        
        wakeUpDetector.audioStream = sharedAudioStream
        
        contextManager.add(provideContextDelegate: wakeUpDetector)
    }
}
