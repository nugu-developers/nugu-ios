//
//  NuguCentralManager.swift
//  SampleApp
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

import NuguCore
import NuguAgents
import NuguClientKit
import NuguLoginKit

final class NuguCentralManager {
    static let shared = NuguCentralManager()

    let client = NuguClient()
    let localTTSAgent: LocalTTSAgent

    lazy private(set) var displayPlayerController: NuguDisplayPlayerController? = NuguDisplayPlayerController(audioPlayerAgent: client.audioPlayerAgent)
    lazy private(set) var oauthClient: NuguOAuthClient = {
        do {
            return try NuguOAuthClient(serviceName: Bundle.main.bundleIdentifier ?? "NuguSample")
        } catch {
            log.warning("OAuthClient has instantiated by using deviceUniqueId")
            return NuguOAuthClient(deviceUniqueId: "sample-device-unique-id")
        }
    }()
    
    var inputStatus: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .nuguClientInputStatus, object: nil, userInfo: ["status": inputStatus])
        }
    }
    
//    var networkStatus: NetworkStatus = .disconnected(error: nil) {
//        didSet {
//            NotificationCenter.default.post(name: .nuguClientNetworkStatus, object: nil, userInfo: ["status": networkStatus])
//        }
//    }
    
    private init() {
        // local tts agent
        localTTSAgent = LocalTTSAgent(focusManager: client.focusManager)
        
        if let epdFile = Bundle(for: type(of: self)).url(forResource: "skt_epd_model", withExtension: "raw") {
            client.asrAgent.epdFile = epdFile
        }

        client.delegate = self
        client.locationAgent.delegate = self
        client.systemAgent.add(systemAgentDelegate: self)

        NuguLocationManager.shared.startUpdatingLocation()
        
        // Set Last WakeUp Keyword
        // If you don't want to use saved wakeup-word, don't need to be implemented
        setWakeUpWord(rawValue: UserDefaults.Standard.wakeUpWord)
    }
}

// MARK: - Internal (Enable / Disable)

extension NuguCentralManager {
    func enable() {
        // TODO: enable/disable 의미 불명확함.
        client.startReceiveServerInitiatedDirective()
    }
    
    func disable() {
        // TODO: enable/disable 의미 불명확함.
        client.stopReceiveServerInitiatedDirective()
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
                    case .failure(let sampleAppError):
                        completion(.failure(sampleAppError))
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
                    completion(.failure(.loginWithRefreshTokenFailed))
                }
            }
        case .type2:
            clientCredentialsLogin { (result) in
                switch result {
                case .success(let authInfo):
                    UserDefaults.Standard.accessToken = authInfo.accessToken
                    completion(.success(()))
                case .failure(let sampleAppError):
                    completion(.failure(sampleAppError))
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
                logoutAfterErrorHandling(sampleAppError: .nilValue(description: "Try to login with refresh token when refresh token is nil"))
                return
            }
            
            // If has refreshToken
            refreshTokenLogin(refreshToken: refreshToken) { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    UserDefaults.Standard.accessToken = authInfo.accessToken
                    UserDefaults.Standard.refreshToken = authInfo.refreshToken
                    self?.enable()
                case .failure(let sampleAppError):
                    self?.logoutAfterErrorHandling(sampleAppError: sampleAppError)
                }
            }
        case .type2:
            clientCredentialsLogin { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    UserDefaults.Standard.accessToken = authInfo.accessToken
                    self?.enable()
                case .failure(let sampleAppError):
                    self?.logoutAfterErrorHandling(sampleAppError: sampleAppError)
                }
            }
        }
    }
    
    func logout() {
        DispatchQueue.main.async { [weak self] in
            guard
                let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let rootNavigationViewController = appDelegate.window?.rootViewController as? UINavigationController else {
                    return
            }
            self?.disable()
            UserDefaults.Standard.clear()
            rootNavigationViewController.popToRootViewController(animated: true)
        }
    }
}

// MARK: - Private (Auth)

private extension NuguCentralManager {
    func authorizationCodeLogin(from viewController: UIViewController, completion: @escaping (Result<AuthorizationInfo, SampleAppError>) -> Void) {
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
            parentViewController: viewController) { (result) in
                completion(result.mapError { SampleAppError.parseFromNuguLoginKitError(error: $0) })
        }
    }
    
    func refreshTokenLogin(refreshToken: String, completion: @escaping (Result<AuthorizationInfo, SampleAppError>) -> Void) {
        guard
            let clientId = SampleApp.clientId,
            let clientSecret = SampleApp.clientSecret else {
                completion(.failure(SampleAppError.nilValue(description: "There is nil value in clientId, clientSecret")))
                return
        }
        
        oauthClient.authorize(grant: RefreshTokenGrant(clientId: clientId, clientSecret: clientSecret, refreshToken: refreshToken)) { (result) in
                completion(result.mapError { SampleAppError.parseFromNuguLoginKitError(error: $0) })
        }
    }
    
    func clientCredentialsLogin(completion: @escaping (Result<AuthorizationInfo, SampleAppError>) -> Void) {
        guard
            let clientId = SampleApp.clientId,
            let clientSecret = SampleApp.clientSecret else {
                completion(.failure(SampleAppError.nilValue(description: "There is nil value in clientId, clientSecret")))
                return
        }
        
        oauthClient.authorize(grant: ClientCredentialsGrant(clientId: clientId, clientSecret: clientSecret)) { (result) in
            completion(result.mapError { SampleAppError.parseFromNuguLoginKitError(error: $0) })
        }
    }
}

// MARK: - Internal (ASR)

extension NuguCentralManager {
    func logoutAfterErrorHandling(sampleAppError: SampleAppError) {
        DispatchQueue.main.async { [weak self] in
            NuguToastManager.shared.showToast(message: sampleAppError.errorDescription)
            switch sampleAppError {
            case .loginUnauthorized:
                self?.localTTSAgent.playLocalTTS(type: .pocStateServiceTerminated, completion: { [weak self] in
                    self?.logout()
                })
            default:
                self?.localTTSAgent.playLocalTTS(type: .deviceGatewayAuthError, completion: { [weak self] in
                    self?.logout()
                })
            }
        }
    }
    
    func startRecognize(initiator: ASRInitiator, completion: ((Result<Void, Error>) -> Void)? = nil) {
        NuguAudioSessionManager.shared.requestRecordPermission { [weak self] isGranted in
            guard let self = self else { return }
            let result = Result<Void, Error>(catching: {
                guard isGranted else { throw SampleAppError.recordPermissionError }
                self.localTTSAgent.stopLocalTTS()
                self.client.asrAgent.startRecognition(initiator: initiator)
            })
            completion?(result)
        }
    }
    
    func stopRecognize() {
        client.asrAgent.stopRecognition()
    }
    
    func cancelRecognize() {
        client.asrAgent.stopRecognition()
        client.ttsAgent.stopTTS()
    }
}

// MARK: - Internal (WakeUpDetector)

extension NuguCentralManager {
    func refreshWakeUpDetector() {
        DispatchQueue.main.async { [weak self] in
            // Should check application state, because iOS audio input can not be start using in background state
            guard UIApplication.shared.applicationState == .active else { return }
            
            guard UserDefaults.Standard.useWakeUpDetector else {
                self?.stopWakeUpDetector()
                return
            }
            
            self?.startWakeUpDetector { (result) in
                if case let .failure(error) = result {
                    log.debug("Failed to start WakeUp-Detector with reason: \(error)")
                }
            }
        }
    }
    
    func startWakeUpDetector(completion: ((Result<Void, Error>) -> Void)? = nil) {
        NuguAudioSessionManager.shared.requestRecordPermission { [weak self] isGranted in
            guard let self = self else { return }
            let result = Result<Void, Error>(catching: {
                guard isGranted else { throw SampleAppError.recordPermissionError }
                self.client.keywordDetector.start()
            })
            completion?(result)
        }
    }
    
    func stopWakeUpDetector() {
        client.keywordDetector.stop()
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
            
            client.keywordDetector.keywordSource = KeywordSource(
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
            
            client.keywordDetector.keywordSource = KeywordSource(
                keyword: .tinkerbell,
                netFileUrl: netFile,
                searchFileUrl: searchFile
            )
        default:
            return
        }
    }
}

// MARK: - NuguClientDelegate

extension NuguCentralManager: NuguClientDelegate {
    func nuguClientRequestAccessToken() -> String? {
        return UserDefaults.Standard.accessToken
    }
    
    func nuguClientWillRequireAudioSession() -> Bool {
        return NuguAudioSessionManager.shared.updateAudioSession()
    }
    
    func nuguClientDidReleaseAudioSession() {
        NuguAudioSessionManager.shared.notifyAudioSessionDeactivationIfNeeded()
    }
    
    // TODO: 더이상 nugu client에서 network 상태를 전달하지 않음.
//    func nuguClientConnectionStatusChanged(status: NetworkStatus) {
//        networkStatus = status
//    }
    
    func nuguClientWillOpenInputSource() {
        inputStatus = true
    }
    
    func nuguClientDidCloseInputSource() {
        inputStatus = false
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
            localTTSAgent.playLocalTTS(type: .deviceGatewayPlayRouterConnectionError)
        case .ttsSpeakingException:
            localTTSAgent.playLocalTTS(type: .deviceGatewayTTSConnectionError)
        case .unauthorizedRequestException:
            handleAuthError()
        }
    }
    
    func systemAgentDidReceiveRevokeDevice() {
        logoutAfterErrorHandling(sampleAppError: .deviceRevoked)
    }
}

extension Notification.Name {
    static let nuguClientInputStatus = NSNotification.Name("Audio_Input_Status_Notification_Name")
    static let nuguClientNetworkStatus = NSNotification.Name("Audio_Network_Status_Notification_Name")
}
