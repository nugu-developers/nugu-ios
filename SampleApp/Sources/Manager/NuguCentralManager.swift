//
//  NuguCentralManager.swift
//  SampleApp-iOS
//
//  Created by yonghoonKwon on 25/07/2019.
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

import UIKit

import NuguInterface
import NuguClientKit

final class NuguCentralManager {
    static let shared = NuguCentralManager()
    let client = NuguClient.default
    lazy private(set) var displayPlayerController = NuguDisplayPlayerController(client: client)
    
    private init() {
        client.authorizationStore.delegate = self
        client.focusManager.delegate = self
        
        if let epdFile = Bundle(for: type(of: self)).url(forResource: "skt_epd_model", withExtension: "raw") {
            client.endPointDetector?.epdFile = epdFile
        }
        
        client.locationAgent?.delegate = self

        NuguLocationManager.shared.startUpdatingLocation()
        
        /// Set Last WakeUp Keyword
        /// If you don't want to use saved wakeup-word, don't need to be implemented
        setWakeUpWord(rawValue: UserDefaults.Standard.wakeUpWord)
    }
}

// MARK: - Internal

extension NuguCentralManager {
    func enable(accessToken: String) {
        client.networkManager.connect()
    }
    
    func disable() {
        client.focusManager.stopForegroundActivity()
        client.networkManager.disconnect()
        client.inputProvider?.stop()
    }
}

// MARK: - Internal (ASR)

extension NuguCentralManager {
    func startRecognize(completion: ((Result<Void, Error>) -> Void)? = nil) {
        NuguAudioSessionManager.requestRecordPermission { [weak self] isGranted in
            guard let self = self else { return }
            let result = Result<Void, Error>(catching: {
                guard isGranted else { throw SampleAppError.recordPermissionError }
                self.client.asrAgent?.startRecognition()
            })
            completion?(result)
        }
    }
    
    func stopRecognize() {
        client.asrAgent?.stopRecognition()
    }
    
    func cancelRecognize() {
        client.asrAgent?.stopRecognition()
        
        client.focusManager.stopForegroundActivity()
    }
}

// MARK: - Internal (WakeUpDetector)

extension NuguCentralManager {
    func refreshWakeUpDetector() {
        DispatchQueue.main.async { [weak self] in
            // Should check application state, because iOS audio input can not be start using in background state
            guard UIApplication.shared.applicationState == .active else { return }
            switch UserDefaults.Standard.useWakeUpDetector {
            case true:
                self?.startWakeUpDetector(completion: { (result) in
                    switch result {
                    case .success: return
                    case .failure(let error):
                        log.debug("Failed to start WakeUp-Detector with reason: \(error)")
                    }
                })
            case false:
                self?.stopWakeUpDetector()
            }
        }
    }
    
    func startWakeUpDetector(completion: ((Result<Void, Error>) -> Void)? = nil) {
        NuguAudioSessionManager.requestRecordPermission { [weak self] isGranted in
            guard let self = self else { return }
            let result = Result<Void, Error>(catching: {
                guard isGranted else { throw SampleAppError.recordPermissionError }
                self.client.wakeUpDetector?.start()
            })
            completion?(result)
        }
    }
    
    func stopWakeUpDetector() {
        client.wakeUpDetector?.stop()
    }
    
    func setWakeUpWord(rawValue wakeUpWord: Int) {
        switch wakeUpWord {
        case Keyword.aria.rawValue:
            guard
                let netFile = Bundle.main.url(forResource: "skt_trigger_am_aria", withExtension: "raw"),
                let searchFile = Bundle.main.url(forResource: "skt_trigger_search_aria", withExtension: "raw") else {
                    log.debug("keywordSource is invalid")
                    return
            }
            
            client.wakeUpDetector?.keywordSource = KeywordSource(
                keyword: .aria,
                netFileUrl: netFile,
                searchFileUrl: searchFile
            )
        case Keyword.tinkerbell.rawValue:
            guard
                let netFile = Bundle.main.url(forResource: "skt_trigger_am_tinkerbell", withExtension: "raw"),
                let searchFile = Bundle.main.url(forResource: "skt_trigger_search_tinkerbell", withExtension: "raw") else {
                    log.debug("keywordSource is invalid")
                    return
            }
            
            client.wakeUpDetector?.keywordSource = KeywordSource(
                keyword: .tinkerbell,
                netFileUrl: netFile,
                searchFileUrl: searchFile
            )
        default:
            return
        }
    }
}

// MARK: - FocusDelegate

extension NuguCentralManager: FocusDelegate {
    func focusShouldAcquire() -> Bool {
        return NuguAudioSessionManager.setAudioSession()
    }
    
    func focusShouldRelease() {
        NuguAudioSessionManager.nofifyAudioSessionDeactivationAndRecover()
    }
}

// MARK: - LocationAgentDelegate

extension NuguCentralManager: LocationAgentDelegate {
    func locationAgentRequestLocationInfo() -> LocationInfo? {
        return NuguLocationManager.shared.cachedLocationInfo
    }
}

// MARK: - AuthorizationStoreDelegate

extension NuguCentralManager: AuthorizationStoreDelegate {
    func authorizationStoreRequestAccessToken() -> String? {
        return UserDefaults.Standard.accessToken
    }
}
