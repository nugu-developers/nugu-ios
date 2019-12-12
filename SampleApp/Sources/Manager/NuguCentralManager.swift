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
import NuguLoginKit

final class NuguCentralManager {
    static let shared = NuguCentralManager()
    let client = NuguClient(capabilityAgentFactory: BuiltInCapabilityAgentFactory())
    lazy private(set) var displayPlayerController = NuguDisplayPlayerController(client: client)
    
    private init() {
        client.focusManager.delegate = self
        
        if let epdFile = Bundle(for: type(of: self)).url(forResource: "skt_epd_model", withExtension: "raw") {
            client.endPointDetector.epdFile = epdFile
        }
        
        client.locationAgent?.delegate = self
        client.systemAgent.add(systemAgentDelegate: self)

        NuguLocationManager.shared.startUpdatingLocation()
        
        /// Set Last WakeUp Keyword
        /// If you don't want to use saved wakeup-word, don't need to be implemented
        setWakeUpWord(rawValue: UserDefaults.Standard.wakeUpWord)
    }
}

// MARK: - Internal (Enable / Disable)

extension NuguCentralManager {
    func enable(accessToken: String) {
        client.accessToken = accessToken
        client.networkManager.connect()
    }
    
    func disable() {
        client.focusManager.stopForegroundActivity()
        client.networkManager.disconnect()
        client.accessToken = nil
        client.inputProvider.stop()
    }
}

// MARK: - Internal (Auth)

extension NuguCentralManager {
    func login(viewController: UIViewController, completion: @escaping (Result<Void, SampleAppError>) -> Void) {
        guard let loginMethod = SampleApp.loginMethod else {
            completion(.failure(SampleAppError.nilValue(description: "loginMethod is nil")))
            return
        }
        switch loginMethod {
        case .type1:
            guard let clientId = SampleApp.clientId,
                let clientSecret = SampleApp.clientSecret,
                let redirectUri = SampleApp.redirectUri else {
                    completion(.failure(SampleAppError.nilValue(description: "clientId, clientSecret, redirectUri is nil")))
                    return
            }

            OAuthManager<Type1>.shared.loginTypeInfo = Type1(
                clientId: clientId,
                clientSecret: clientSecret,
                redirectUri: redirectUri,
                deviceUniqueId: SampleApp.deviceUniqueId
            )
            
            guard let refreshToken = UserDefaults.Standard.refreshToken else {
                OAuthManager<Type1>.shared.loginBySafariViewController(from: viewController) { (result) in
                    guard case .success(let authorizationInfo) = result else {
                        completion(.failure(SampleAppError.loginFailedError(loginMethod: .type1)))
                        return
                    }
                    UserDefaults.Standard.accessToken = authorizationInfo.accessToken
                    UserDefaults.Standard.refreshToken = authorizationInfo.refreshToken
                    completion(.success(()))
                }
                return
            }
            
            loginWithRefreshToken(refreshToken: refreshToken) { (result) in
                guard case .success = result else {
                    completion(.failure(SampleAppError.loginWithRefreshTokenFailedError))
                    return
                }
                completion(.success(()))
            }
        case .type2:
            guard let clientId = SampleApp.clientId,
                let clientSecret = SampleApp.clientSecret else {
                    completion(.failure(SampleAppError.nilValue(description: "clientId, clientSecret is nil")))
                    return
            }
            
            OAuthManager<Type2>.shared.loginTypeInfo = Type2(
                clientId: clientId,
                clientSecret: clientSecret,
                deviceUniqueId: SampleApp.deviceUniqueId
            )
            
            OAuthManager<Type2>.shared.login(completion: { (result) in
                guard case .success(let authorizationInfo) = result else {
                    completion(.failure(SampleAppError.loginFailedError(loginMethod: .type2)))
                    return
                }
                UserDefaults.Standard.accessToken = authorizationInfo.accessToken
                completion(.success(()))
            })
        }
    }
    
    func handleAuthError() {
        switch SampleApp.loginMethod {
        case .type1:
            guard let refreshToken = UserDefaults.Standard.refreshToken else {
                log.debug("Try to login with refresh token when refresh token is nil")
                logoutAfterErrorHandling()
                return
            }
            loginWithRefreshToken(refreshToken: refreshToken) { [weak self] (result) in
                guard case .success = result else {
                    self?.logoutAfterErrorHandling()
                    return
                }
                self?.enable(accessToken: UserDefaults.Standard.accessToken ?? "")
            }
        case .type2:
            logoutAfterErrorHandling()
        default:
            break
        }
    }
    
    func logout() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let rootNavigationViewController = appDelegate.window?.rootViewController as? UINavigationController else { return }
        disable()
        UserDefaults.Standard.clear()
        rootNavigationViewController.popToRootViewController(animated: true)
    }
}

// MARK: - Private (Auth)

private extension NuguCentralManager {
    func loginWithRefreshToken(refreshToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        OAuthManager<Type1>.shared.loginSilently(by: refreshToken) { result in
            switch result {
            case .success(let authorizationInfo):
                UserDefaults.Standard.accessToken = authorizationInfo.accessToken
                UserDefaults.Standard.refreshToken = authorizationInfo.refreshToken
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func logoutAfterErrorHandling() {
        DispatchQueue.main.async { [weak self] in
            SoundPlayer.playSound(soundType: .localTts(type: .deviceGatewayAuthError))
            NuguToastManager.shared.showToast(message: "누구 앱과의 연결이 해제되었습니다. 다시 연결해주세요.")
            self?.logout()
        }
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

// MARK: - SystemAgentDelegate

extension NuguCentralManager: SystemAgentDelegate {
    func systemAgentDidReceiveExceptionFail(code: SystemAgentExceptionCode.Fail) {
        switch code {
        case .playRouterProcessingException:
            SoundPlayer.playSound(soundType: .localTts(type: .deviceGatewayPlayRouterConnectionError))
        case .ttsSpeakingException:
            SoundPlayer.playSound(soundType: .localTts(type: .deviceGatewayTtsConnectionError))
        case .unauthorizedRequestException:
            handleAuthError()
        }
    }
}
