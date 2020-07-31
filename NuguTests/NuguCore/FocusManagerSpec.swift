//
//  FocusManagerSpec.swift
//  NuguTests
//
//  Created by MinChul Lee on 2020/07/30.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

import Quick
import Nimble

@testable import NuguCore
@testable import NuguAgents

var channelInfos = [String: FocusState]()
let userRecognition = FocusChannel(name: "userRecognition", priority: .userRecognition)
let call = FocusChannel(name: "call", priority: .call)
let alerts = FocusChannel(name: "alerts", priority: .alerts)
let information = FocusChannel(name: "information", priority: .information)
let media = FocusChannel(name: "media", priority: .media)
let dmRecognition = FocusChannel(name: "dmRecognition", priority: .dmRecognition)

class FocusManagerSpec: QuickSpec, FocusDelegate {
    override func spec() {
        let channels = [userRecognition, call, alerts, information, media, dmRecognition]
        describe("FocusManager") {
            channels.forEach { (current) in
                channels.forEach { (next) in
                    it("request \(next.name) when \(current.name) is progressing") {
                        let currentFocus: FocusState
                        let nextFocus: FocusState
                        if current === call {
                            if next === call || next === userRecognition {
                                currentFocus = .background
                                nextFocus = .foreground
                            } else {
                                currentFocus = .foreground
                                nextFocus = .background
                            }
                        } else if next === dmRecognition {
                            if current === dmRecognition || current === media {
                                currentFocus = .background
                                nextFocus = .foreground
                            } else {
                                currentFocus = .foreground
                                nextFocus = .background
                            }
                        } else {
                            currentFocus = .background
                            nextFocus = .foreground
                        }
                        self.focusTest(current: current, next: next, currentFocus: currentFocus, nextFocus: nextFocus)
                    }
                }
            }
        }
    }
    
    func focusTest(current: FocusChannel, next: FocusChannel, currentFocus: FocusState, nextFocus: FocusState) {
        let focusManager = self.initializeFocusManager()
        var expectResult: [String: FocusState] = [
            userRecognition.name: .nothing,
            call.name: .nothing,
            alerts.name: .nothing,
            information.name: .nothing,
            media.name: .nothing,
            dmRecognition.name: .nothing
        ]
        
        // ASR -> Call
        focusManager.requestFocus(channelDelegate: current)
        focusManager.requestFocus(channelDelegate: next)
        expectResult[current.name] = currentFocus
        expectResult[next.name] = nextFocus
        expect(channelInfos).toEventually(equal(expectResult))
    }
    
    func initializeFocusManager() -> FocusManageable {
        let focusManager = FocusManager()
        focusManager.delegate = self
        focusManager.add(channelDelegate: call)
        focusManager.add(channelDelegate: userRecognition)
        focusManager.add(channelDelegate: dmRecognition)
        focusManager.add(channelDelegate: alerts)
        focusManager.add(channelDelegate: information)
        focusManager.add(channelDelegate: media)
        
        channelInfos[userRecognition.name] = .nothing
        channelInfos[call.name] = .nothing
        channelInfos[alerts.name] = .nothing
        channelInfos[information.name] = .nothing
        channelInfos[media.name] = .nothing
        channelInfos[dmRecognition.name] = .nothing
        
        return focusManager
    }
    
    func focusShouldAcquire() -> Bool {
        true
    }
    
    func focusShouldRelease() {
    }
}

class FocusChannel: FocusChannelDelegate {
    let name: String
    let priority: FocusChannelPriority
    
    init(name: String, priority: FocusChannelPriority) {
        self.name = name
        self.priority = priority
    }
    
    func focusChannelPriority() -> FocusChannelPriority {
        return priority
    }
    
    func focusChannelDidChange(focusState: FocusState) {
        channelInfos[name] = focusState
    }
}
