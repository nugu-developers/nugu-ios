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

final class NuguAudioSessionManager {
    
    static let shared = NuguAudioSessionManager()
    
    @objc private func interruptionNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        switch type {
        case .began:
            // Interruption began, take appropriate actions
            NuguCentralManager.shared.client.audioPlayerAgent?.pause()
            allowMixWithOthers()
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    NuguCentralManager.shared.client.audioPlayerAgent?.play()
                } else {
                    // Interruption Ended - playback should NOT resume
                }
            }
        @unknown default: break
        }
    }
}

// MARK: - Internal

extension NuguAudioSessionManager {
    
    func observeAVAudioSessionInterruptionNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(interruptionNotification(_ :)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    func removeObservingAVAudioSessionInterruptionNotification() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    func requestRecordPermission(_ response: @escaping PermissionBlock) {
        AVAudioSession.sharedInstance().requestRecordPermission { (isGranted) in
            response(isGranted)
        }
    }
    
    func allowMixWithOthers() {
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
    
    @discardableResult func setAudioSession() -> Bool {
        // if mixWithOthers option is already included, resetting audioSession is unnecessary
        guard AVAudioSession.sharedInstance().categoryOptions.contains(.mixWithOthers) == true else {
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
    
    func nofifyAudioSessionDeactivationAndRecover() {
        // clean up all I/O before deactivating audioSession
        NuguCentralManager.shared.stopWakeUpDetector()
        if NuguCentralManager.shared.client.inputProvider.isRunning == true {
            NuguCentralManager.shared.client.inputProvider.stop()
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
    }
}
