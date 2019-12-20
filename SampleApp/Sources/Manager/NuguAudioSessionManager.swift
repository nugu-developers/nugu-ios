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
    
    /// NUGU Service should set AudioSession.Category as .playAndRecord for recording voice and playing media
    /// Setting AudioSession.Category as .playAndRecord leads you to stop on going 3rd party app's music player
    /// To avoid 3rd party app's music player being stopped, application should append .mixWithOthers option to AudioSession.CategoryOptions
    /// To support mixWithOthersOption, simply change following value to 'true'
    let supportMixWithOthersOption = false
    
    @objc private func interruptionNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            // Interruption began, take appropriate actions
            NuguCentralManager.shared.client.audioPlayerAgent?.pause()
            if supportMixWithOthersOption == true {
                allowMixWithOthers()
            }
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
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
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
    
    func initializeAudioSession() {
        if supportMixWithOthersOption == true {
            allowMixWithOthers()
        } else {
            setAudioSession()
        }
    }
    
    @discardableResult func setAudioSession() -> Bool {
        if supportMixWithOthersOption == true {
            // if mixWithOthers option is already included, resetting audioSession is unnecessary
            guard AVAudioSession.sharedInstance().categoryOptions.contains(.mixWithOthers) == true else {
                return true
            }
        } else {
            // if category is already .playAndRecord, resetting audioSession is unnecessary
            guard AVAudioSession.sharedInstance().category != .playAndRecord else {
                return true
            }
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

// MARK: - private

private extension NuguAudioSessionManager {
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
}
