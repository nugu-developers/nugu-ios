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

import NuguAgents

final class NuguAudioSessionManager {
    static let shared = NuguAudioSessionManager()
    
    /// NUGU Service should set AudioSession.Category as .playAndRecord for recording voice and playing media
    /// Setting AudioSession.Category as .playAndRecord leads you to stop on going 3rd party app's music player
    /// To avoid 3rd party app's music player being stopped, application should append .mixWithOthers option to AudioSession.CategoryOptions
    /// To support mixWithOthersOption, simply change following value to 'true'
    let supportMixWithOthersOption = false
    
    private let defaultCategoryOptions = AVAudioSession.CategoryOptions(arrayLiteral: [.defaultToSpeaker, .allowBluetoothA2DP])
}

// MARK: - Internal

extension NuguAudioSessionManager {
    func requestRecordPermission(_ response: @escaping PermissionBlock) {
        AVAudioSession.sharedInstance().requestRecordPermission { (isGranted) in
            response(isGranted)
        }
    }
    
    func observeAVAudioSessionInterruptionNotification() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(interruptionNotification(_ :)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    func removeObservingAVAudioSessionInterruptionNotification() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    @discardableResult func updateAudioSession() -> Bool {
        // When AudioSession default value has not been set, updating AudioSession should be done first
        guard AVAudioSession.sharedInstance().category == .playAndRecord,
            AVAudioSession.sharedInstance().categoryOptions.contains(defaultCategoryOptions) else {
                return updateAudioSessionCategoryWithOptions()
        }
        return updateAudioSessionCategoryWithOptions(requestingFocus: true)
    }
     
    func notifyAudioSessionDeactivationIfNeeded() {
        // NotifyOthersOnDeactivation is unnecessory when .mixWithOthers option is off
        guard supportMixWithOthersOption == true else { return }
        
        NotificationCenter.default.removeObserver(self, name: .nuguClientInputStatus, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(inputStatusDidChanged(_ :)), name: .nuguClientInputStatus, object: nil)
        
        // Clean up all I/O before deactivating audioSession
        NuguCentralManager.shared.stopWakeUpDetector()
    }
    
    @objc func inputStatusDidChanged(_ notification: Notification) {
        guard let status = notification.userInfo?["status"] as? Bool,
            status == false else {
                return
        }
        
        do {
            // Defer statement for recovering audioSession and wakeUpDetector
            defer {
                updateAudioSessionCategoryWithOptions()
                NuguCentralManager.shared.refreshWakeUpDetector()
            }
            // Notify audio session deactivation to 3rd party apps
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            log.debug("notifyOthersOnDeactivation failed: \(error)")
        }
        
        NotificationCenter.default.removeObserver(self, name: .nuguClientInputStatus, object: nil)
    }
}

// MARK: - private

private extension NuguAudioSessionManager {
    @objc func interruptionNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            // Interruption began, take appropriate actions
            NuguCentralManager.shared.client.audioPlayerAgent.pause()
            
            // When supportMixWithOthersOption is on,
            // AudioSession's category option should be changed as including mixWithOthers option when paused with interruption.
            // Otherwise, 3rd party app's music player will stop when user returns to this app.
            if supportMixWithOthersOption == true {
                updateAudioSessionCategoryWithOptions()
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    NuguCentralManager.shared.client.audioPlayerAgent.play()
                } else {
                    // Interruption Ended - playback should NOT resume
                }
            }
        @unknown default: break
        }
    }
    
    /// Update AudioSession.Category and AudioSession.CategoryOptions
    /// - Parameter requestingFocus: whether updating AudioSession is for requesting focus or just updating without requesting focus
    @discardableResult func updateAudioSessionCategoryWithOptions(requestingFocus: Bool = false) -> Bool {
        var options = defaultCategoryOptions
        if requestingFocus == false && supportMixWithOthersOption == true {
            options.insert(.mixWithOthers)
        }
        
        // If audioSession is already has been set properly, resetting audioSession is unnecessary
        guard AVAudioSession.sharedInstance().category != .playAndRecord || AVAudioSession.sharedInstance().categoryOptions != options else {
            return true
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: options
            )
            try AVAudioSession.sharedInstance().setActive(true)
            return true
        } catch {
            log.debug("updateAudioSessionCategoryOptions failed: \(error)")
            return false
        }
    }
}
