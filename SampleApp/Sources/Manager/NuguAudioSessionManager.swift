//
//  NuguAudioSessionManager.swift
//  SampleApp
//
//  Created by jin kim on 2019/11/29.
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

import AVFoundation

struct NuguAudioSessionManager {
    
    static func requestRecordPermission(_ response: @escaping PermissionBlock) {
        AVAudioSession.sharedInstance().requestRecordPermission { (isGranted) in
            response(isGranted)
        }
    }
    
    static func allowMixWithOthers() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            log.debug("addingMixWithOthers failed: \(error)")
        }
    }
    
    @discardableResult static func setAudioSession() -> Bool {
        // check whether other application is playing audio to disable mixWithOthers option
        // if mixWithOthers option is already included, resetting audioSession is unnecessary
        guard AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint == true,
            AVAudioSession.sharedInstance().categoryOptions.contains(.mixWithOthers) == true else {
                return true
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            return true
        } catch {
            log.debug("setCategory failed: \(error)")
            return false
        }
    }
    
    static func nofifyAudioSessionDeactivationAndRecover() {
        // check whether mixWithOthers option is included or not,
        // to determine secondaryAudio has been interrupted or not
        // if not, calling notifyOthersOnDeactivation is unnecessary
        guard AVAudioSession.sharedInstance().categoryOptions.contains(.mixWithOthers) == false else { return }
        // need delay for audioPlayer to be 'really' stopped
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: {
            if NuguCentralManager.shared.client.inputProvider?.isRunning == true {
                NuguCentralManager.shared.client.inputProvider?.stop()
            }
            do {
                defer {
                    self.allowMixWithOthers()
                    NuguCentralManager.shared.refreshWakeUpDetector()
                }
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                log.debug("notifyOthersOnDeactivation failed: \(error)")
            }
        })
    }
}
