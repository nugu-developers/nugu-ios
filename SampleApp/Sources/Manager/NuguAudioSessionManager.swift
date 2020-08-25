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
import UIKit

import NuguAgents

final class NuguAudioSessionManager {
    static let shared = NuguAudioSessionManager()
    private let defaultCategoryOptions = AVAudioSession.CategoryOptions(arrayLiteral: [.defaultToSpeaker, .allowBluetoothA2DP])
    
    init() {
        addAudioInterruptionNotification()
    }
    var pausedByInterruption = false
}

// MARK: - Internal

extension NuguAudioSessionManager {
    func addAudioInterruptionNotification() {
        removeAudioInterruptionNotification()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(interruptionNotification),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
    }
    
    func removeAudioInterruptionNotification() {
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.interruptionNotification,
                                                  object: nil)
    }
    
    func addEngineConfigurationChangeNotification() {
        removeEngineConfigurationChangeNotification()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(engineConfigurationChange),
                                               name: .AVAudioEngineConfigurationChange,
                                               object: nil)
    }
    
    func removeEngineConfigurationChangeNotification() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVAudioEngineConfigurationChange,
                                                  object: nil)
    }
    
    func requestRecordPermission(_ response: @escaping PermissionBlock) {
        AVAudioSession.sharedInstance().requestRecordPermission { (isGranted) in
            response(isGranted)
        }
    }
    
    /// Update AudioSession.Category and AudioSession.CategoryOptions
    /// - Parameter requestingFocus: whether updating AudioSession is for requesting focus or just updating without requesting focus
    @discardableResult func updateAudioSession(requestingFocus: Bool = false) -> Bool {
        var options = defaultCategoryOptions
        if requestingFocus == false {
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
            log.debug("set audio session = \(options)")
            return true
        } catch {
            log.debug("updateAudioSessionCategoryOptions failed: \(error)")
            return false
        }
    }
    
    func notifyAudioSessionDeactivation() {
        log.debug("")
        // Defer statement for recovering audioSession and MicInputProvider
        defer {
            updateAudioSession()
            if UserDefaults.Standard.useWakeUpDetector == true {
                NuguCentralManager.shared.startMicInputProvider(requestingFocus: false) { success in
                    log.debug("startMicInputProvider : \(success)")
                }
            }
        }
        do {
            // Clean up all I/O before deactivating audioSession
            NuguCentralManager.shared.stopMicInputProvider()
            
            // Notify audio session deactivation to 3rd party apps
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            log.debug("notifyOthersOnDeactivation failed: \(error)")
        }
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
            log.debug("Interruption began")
            // Interruption began, take appropriate actions
            if NuguCentralManager.shared.client.audioPlayerAgent.isPlaying == true {
                NuguCentralManager.shared.client.audioPlayerAgent.pause()
                DispatchQueue.global().asyncAfter(deadline: .now()+0.1) { [weak self] in
                    self?.pausedByInterruption = true
                }
            }
            NuguCentralManager.shared.client.ttsAgent.stopTTS(cancelAssociation: false)
        case .ended:
            log.debug("Interruption ended")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    if UserDefaults.Standard.useWakeUpDetector == true {
                        NuguCentralManager.shared.startMicInputProvider(requestingFocus: false) { (success) in
                            log.debug("startMicInputProvider: \(success)")
                        }
                    }
                    if pausedByInterruption == true || NuguCentralManager.shared.client.audioPlayerAgent.isPlaying == true {
                        NuguCentralManager.shared.client.audioPlayerAgent.play()
                    }
                } else {
                    // Interruption Ended - playback should NOT resume
                }
            }
        @unknown default: break
        }
    }
    
    /// recover when the audio engine is stopped by OS.
    @objc func engineConfigurationChange(notification: Notification) {
        if UserDefaults.Standard.useWakeUpDetector == true {
            NuguCentralManager.shared.startMicInputProvider(requestingFocus: false) { (success) in
                log.debug("startMicInputProvider: \(success)")
            }
        }
    }
}
