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
    lazy private(set) var oauthClient: NuguOAuthClient = {
        do {
            return try NuguOAuthClient(serviceName: Bundle.main.bundleIdentifier ?? "NuguSample")
        } catch {
            log.warning("OAuthClient has instantiated by using deviceUniqueId")
            return NuguOAuthClient(deviceUniqueId: "sample-device-unique-id")
        }
    }()
    
    private init() {
        client.authorizationStore.delegate = self
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
    func enable() {
        client.networkManager.connect()
    }
    
    func disable() {
        client.focusManager.stopForegroundActivity()
        client.networkManager.disconnect()
        client.inputProvider.stop()
    }
}

// MARK: - Internal (Auth)

extension NuguCentralManager {
    func login(from viewController: UIViewController, completion: @escaping (Result<Void, SampleAppError>) -> Void) {
        guard let loginMethod = SampleApp.loginMethod else {
            completion(.failure(SampleAppError.nilValue(description: "loginMethod is nil")))
            return
        }
        
        switch loginMethod {
        case .type1:
            // If has not refreshToken
            guard let refreshToken = UserDefaults.Standard.refreshToken else {
                authorizationCodeLogin(from: viewController) { (result) in
                    switch result {
                    case .success(let authInfo):
                        UserDefaults.Standard.accessToken = authInfo.accessToken
                        UserDefaults.Standard.refreshToken = authInfo.refreshToken
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(SampleAppError.loginFailed(error: error)))
                    }
                }
                return
            }
            
            // If has refreshToken
            refreshTokenLogin(refreshToken: refreshToken) { (result) in
                switch result {
                case .success(let authInfo):
                    UserDefaults.Standard.accessToken = authInfo.accessToken
                    UserDefaults.Standard.refreshToken = authInfo.refreshToken
                    completion(.success(()))
                case .failure:
                    completion(.failure(SampleAppError.loginWithRefreshTokenFailed))
                }
            }
        case .type2:
            clientCredentialsLogin { (result) in
                switch result {
                case .success(let authInfo):
                    UserDefaults.Standard.accessToken = authInfo.accessToken
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(SampleAppError.loginFailed(error: error)))
                }
            }
        }
    }
    
    func handleAuthError() {
        guard let loginMethod = SampleApp.loginMethod else {
            log.info("loginMethod is nil")
            return
        }
        
        switch loginMethod {
        case .type1:
            // If has not refreshToken
            guard let refreshToken = UserDefaults.Standard.refreshToken else {
                log.debug("Try to login with refresh token when refresh token is nil")
                logoutAfterErrorHandling()
                return
            }
            
            // If has refreshToken
            refreshTokenLogin(refreshToken: refreshToken) { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    UserDefaults.Standard.accessToken = authInfo.accessToken
                    UserDefaults.Standard.refreshToken = authInfo.refreshToken
                    self?.enable()
                case .failure:
                    self?.logoutAfterErrorHandling()
                }
            }
        case .type2:
            clientCredentialsLogin { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    UserDefaults.Standard.accessToken = authInfo.accessToken
                    self?.enable()
                case .failure:
                    self?.logoutAfterErrorHandling()
                }
            }
        }
    }
    
    func logout() {
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let rootNavigationViewController = appDelegate.window?.rootViewController as? UINavigationController else {
                return
        }
        
        disable()
        UserDefaults.Standard.clear()
        rootNavigationViewController.popToRootViewController(animated: true)
    }
}

// MARK: - Private (Auth)

private extension NuguCentralManager {
    func authorizationCodeLogin(from viewController: UIViewController, completion: @escaping (Result<AuthorizationInfo, Error>) -> Void) {
        guard
            let clientId = SampleApp.clientId,
            let clientSecret = SampleApp.clientSecret,
            let redirectUri = SampleApp.redirectUri else {
                completion(.failure(SampleAppError.nilValue(description: "There is nil value in clientId, clientSecret, redirectUri")))
                return
        }
        
        oauthClient.authorize(
            grant: AuthorizationCodeGrant(
                clientId: clientId,
                clientSecret: clientSecret,
                redirectUri: redirectUri
            ),
            parentViewController: viewController,
            completion: completion
        )
    }
    
    func refreshTokenLogin(refreshToken: String, completion: @escaping (Result<AuthorizationInfo, Error>) -> Void) {
        guard
            let clientId = SampleApp.clientId,
            let clientSecret = SampleApp.clientSecret else {
                completion(.failure(SampleAppError.nilValue(description: "There is nil value in clientId, clientSecret")))
                return
        }
        
        oauthClient.authorize(
            grant: RefreshTokenGrant(clientId: clientId, clientSecret: clientSecret, refreshToken: refreshToken),
            completion: completion
        )
    }
    
    func clientCredentialsLogin(completion: @escaping (Result<AuthorizationInfo, Error>) -> Void) {
        guard
            let clientId = SampleApp.clientId,
            let clientSecret = SampleApp.clientSecret else {
                completion(.failure(SampleAppError.nilValue(description: "There is nil value in clientId, clientSecret")))
                return
        }
        
        oauthClient.authorize(
            grant: ClientCredentialsGrant(clientId: clientId, clientSecret: clientSecret),
            completion: completion
        )
    }
    
    func logoutAfterErrorHandling() {
        DispatchQueue.main.async { [weak self] in
            LocalTTSPlayer.shared.playLocalTTS(type: .deviceGatewayAuthError)
            NuguToastManager.shared.showToast(message: "누구 앱과의 연결이 해제되었습니다. 다시 연결해주세요.")
            self?.logout()
        }
    }
}

// MARK: - Internal (ASR)

extension NuguCentralManager {
    func startRecognize(completion: ((Result<Void, Error>) -> Void)? = nil) {
        NuguAudioSessionManager.shared.requestRecordPermission { [weak self] isGranted in
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
        NuguAudioSessionManager.shared.requestRecordPermission { [weak self] isGranted in
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
        return NuguAudioSessionManager.shared.updateAudioSession()
    }
    
    func focusShouldRelease() {
        NuguAudioSessionManager.shared.notifyAudioSessionDeactivationIfNeeded()
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

// MARK: - SystemAgentDelegate

extension NuguCentralManager: SystemAgentDelegate {
    func systemAgentDidReceiveExceptionFail(code: SystemAgentExceptionCode.Fail) {
        switch code {
        case .playRouterProcessingException:
            LocalTTSPlayer.shared.playLocalTTS(type: .deviceGatewayPlayRouterConnectionError)
        case .ttsSpeakingException:
            LocalTTSPlayer.shared.playLocalTTS(type: .deviceGatewayTTSConnectionError)
        case .unauthorizedRequestException:
            handleAuthError()
        }
    }
}
