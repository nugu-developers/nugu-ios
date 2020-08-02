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
import NuguUIKit

final class NuguCentralManager {
    static let shared = NuguCentralManager()
    
    private let supportServerInitiatedDirective = false
    
    lazy private(set) var client: NuguClient = {
        let client = NuguClient(delegate: self)
        
        displayPlayerController = NuguDisplayPlayerController()
        
        // local tts agent
        localTTSAgent = LocalTTSAgent(focusManager: client.focusManager)
        
        client.locationAgent.delegate = self
        client.systemAgent.add(systemAgentDelegate: self)
        client.soundAgent.dataSource = self
        
        return client
    }()
    lazy private(set) var localTTSAgent: LocalTTSAgent = LocalTTSAgent(focusManager: client.focusManager)

    var displayPlayerController: NuguDisplayPlayerController?
    
    lazy private(set) var oauthClient: NuguOAuthClient = {
        do {
            return try NuguOAuthClient(serviceName: Bundle.main.bundleIdentifier ?? "NuguSample")
        } catch {
            log.warning("OAuthClient has instantiated by using deviceUniqueId")
            return NuguOAuthClient(deviceUniqueId: "sample-device-unique-id")
        }
    }()
    
    var isTextAgentInProcess = false
    
    private init() {}
}

// MARK: - Internal (Enable / Disable)

extension NuguCentralManager {
    func enable() {
        log.debug("")
        if supportServerInitiatedDirective {
            client.startReceiveServerInitiatedDirective()
        } else {
            client.stopReceiveServerInitiatedDirective()
        }

        NuguLocationManager.shared.startUpdatingLocation()
        
        // Set Last WakeUp Keyword
        // If you don't want to use saved wakeup-word, don't need to be implemented
        if UserDefaults.Standard.useWakeUpDetector,
            let keyword = Keyword(rawValue: UserDefaults.Standard.wakeUpWord) {
            client.keywordDetector.keywordSource = keyword.keywordSource
            startWakeUpDetector()
        } else {
            stopWakeUpDetector()
        }
    }
    
    func disable() {
        log.debug("")
        stopWakeUpDetector()
        client.stopReceiveServerInitiatedDirective()
        client.asrAgent.stopRecognition()
        client.ttsAgent.stopTTS()
        client.audioPlayerAgent.stop()
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
                clearSampleAppAfterErrorHandling(sampleAppError: .nilValue(description: "Try to login with refresh token when refresh token is nil"))
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
                    self?.clearSampleAppAfterErrorHandling(sampleAppError: sampleAppError)
                }
            }
        case .type2:
            clientCredentialsLogin { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    UserDefaults.Standard.accessToken = authInfo.accessToken
                    self?.enable()
                case .failure(let sampleAppError):
                    self?.clearSampleAppAfterErrorHandling(sampleAppError: sampleAppError)
                }
            }
        }
    }
    
    func revoke() {
        let clearSampleApp = { [weak self] in
            self?.popToRootViewController()
            self?.disable()
            UserDefaults.Standard.clear()
        }
        
        if SampleApp.loginMethod == SampleApp.LoginMethod.type1,
            let clientId = SampleApp.clientId,
            let clientSecret = SampleApp.clientSecret,
            let token = UserDefaults.Standard.accessToken {
            oauthClient.revoke(
                clientId: clientId,
                clientSecret: clientSecret,
                token: token) { (result) in
                    switch result {
                    case .success:
                        clearSampleApp()
                    case .failure(let nuguLoginKitError):
                        log.debug(nuguLoginKitError.localizedDescription)
                    }
            }
        } else {
            clearSampleApp()
        }
    }
}

// MARK: - Internal (User Info)

extension NuguCentralManager {
    func getUserInfo(completion: ((_ userInfo: NuguUserInfo?) -> Void)?) {
        guard let token = UserDefaults.Standard.accessToken else {
            completion?(nil)
            return
        }
        oauthClient.getUserInfo(token: token) { result in
            switch result {
            case .success(let userInfo):
                completion?(userInfo)
            case .failure:
                completion?(nil)
            }
        }
    }
    
    func showTidInfo(parentViewController: UIViewController, completion: ((_ tid: String?) -> Void)?) {
        guard SampleApp.loginMethod == SampleApp.LoginMethod.type1,
            let clientId = SampleApp.clientId,
            let clientSecret = SampleApp.clientSecret,
            let redirectUri = SampleApp.redirectUri else {
                completion?(nil)
                return
        }
        
        getUserInfo { [weak self] (userInfo) in
            guard let tid = userInfo?.tid else {
                completion?(nil)
                return
            }
            let authorizationCodeGrant = AuthorizationCodeGrant(
                clientId: clientId,
                clientSecret: clientSecret,
                redirectUri: redirectUri
            )
            self?.oauthClient.showTidInfo(
                grant: authorizationCodeGrant,
                loginTid: tid,
                parentViewController: parentViewController,
                completion: { [weak self] (result) in
                    if case .success(let authInfo) = result {
                        UserDefaults.Standard.accessToken = authInfo.accessToken
                        UserDefaults.Standard.refreshToken = authInfo.refreshToken
                    }
                    self?.getUserInfo(completion: { (userInfo) in
                        completion?(userInfo?.tid)
                    })
            })
        }
    }
}

// MARK: - Private (Clear Sample App)

private extension NuguCentralManager {
    func popToRootViewController() {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let rootNavigationViewController = appDelegate.window?.rootViewController as? UINavigationController else { return }
            rootNavigationViewController.popToRootViewController(animated: true)
        }
    }
    
    func clearSampleAppAfterErrorHandling(sampleAppError: SampleAppError) {
        DispatchQueue.main.async { [weak self] in
            self?.client.audioPlayerAgent.stop()
            NuguToast.shared.showToast(message: sampleAppError.errorDescription)
            self?.popToRootViewController()
            switch sampleAppError {
            case .loginUnauthorized:
                self?.localTTSAgent.playLocalTTS(type: .pocStateServiceTerminated, completion: { [weak self] in
                    self?.disable()
                    UserDefaults.Standard.clear()
                })
            default:
                self?.localTTSAgent.playLocalTTS(type: .deviceGatewayAuthError, completion: { [weak self] in
                    self?.disable()
                    UserDefaults.Standard.clear()
                })
            }
        }
    }
}

// MARK: - Private (NetworkError handling)
// TODO: - Should consider and decide for best way for handling network errors

private extension NuguCentralManager {
    func handleNetworkError(error: Error) {
        // Handle Nugu's predefined NetworkError
        if let networkError = error as? NetworkError {
            switch networkError {
            case .authError:
                handleAuthError()
            case .timeout:
                localTTSAgent.playLocalTTS(type: .deviceGatewayTimeout)
            default:
                localTTSAgent.playLocalTTS(type: .deviceGatewayAuthServerError)
            }
        } else { // Handle URLError
            guard let urlError = error as? URLError else { return }
            switch urlError.code {
            case .networkConnectionLost, .notConnectedToInternet: // In unreachable network status, play prepared local tts (deviceGatewayNetworkError)
                NuguCentralManager.shared.localTTSAgent.playLocalTTS(type: .deviceGatewayNetworkError)
            default: // Handle other URLErrors with your own way
                break
            }
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

// MARK: - Internal (WakeUpDetector)

extension NuguCentralManager {
    func startWakeUpDetector() {
        DispatchQueue.main.async { [weak self] in
            // Should check application state, because iOS audio input can not be start using in background state
            guard UIApplication.shared.applicationState == .active else { return }
            guard UserDefaults.Standard.useWakeUpDetector else { return }

            self?.startMicInputProvider(requestingFocus: false) { [weak self] (success) in
                guard success else {
                    log.error("Start MicInputProvider failed")
                    return
                }
                self?.client.keywordDetector.start()
            }
        }
    }
    
    func stopWakeUpDetector() {
        client.keywordDetector.stop()
    }
    
    func startMicInputProvider(requestingFocus: Bool, completion: @escaping (Bool) -> Void) {
        NuguAudioSessionManager.shared.requestRecordPermission { [weak self] isGranted in
            guard isGranted else {
                log.error("Record permission denied")
                completion(false)
                return
            }
            DispatchQueue.global().async { [weak self] in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                self.client.inputProvider.stop()
                if requestingFocus {
                    NuguAudioSessionManager.shared.updateAudioSession(requestingFocus: requestingFocus)
                }
                do {
                    try self.client.inputProvider.start(streamWriter: self.client.sharedAudioStream.makeAudioStreamWriter())
                    completion(true)
                } catch {
                    log.error(error)
                    completion(false)
                }
            }
        }
    }
}

// MARK: - NuguClientDelegate

extension NuguCentralManager: NuguClientDelegate {
    func nuguClientRequestAccessToken() -> String? {
        return UserDefaults.Standard.accessToken
    }
    
    func nuguClientWillRequireAudioSession() -> Bool {
        return NuguAudioSessionManager.shared.updateAudioSession(requestingFocus: true)
    }
    
    func nuguClientDidReleaseAudioSession() {
        if isTextAgentInProcess == false {
            // Clean up all I/O before deactivating audioSession
            client.inputProvider.stop()
            NuguAudioSessionManager.shared.notifyAudioSessionDeactivation()
        }
    }
    
    func nuguClientDidReceive(direcive: Downstream.Directive) {
        // Use some analytics SDK(or API) here.
        log.debug("\(direcive.header.namespace).\(direcive.header.name)")
    }
    
    func nuguClientDidReceive(attachment: Downstream.Attachment) {
        // Use some analytics SDK(or API) here.
        log.debug("\(attachment.header.namespace).\(attachment.header.name)")
    }
    
    func nuguClientWillSend(event: Upstream.Event) {
        // Use some analytics SDK(or API) here.
        log.debug("\(event.header.namespace).\(event.header.name)")
    }
    
    func nuguClientDidSend(event: Upstream.Event, error: Error?) {
        // Use some analytics SDK(or API) here.
        // Error: URLError or NetworkError or EventSenderError
        log.debug("\(error?.localizedDescription ?? ""): \(event.header.namespace).\(event.header.name)")
        guard let error = error else { return }
        handleNetworkError(error: error)
    }
    
    func nuguClientDidSend(attachment: Upstream.Attachment, error: Error?) {
        // Use some analytics SDK(or API) here.
        // Error: EventSenderError
        log.debug("\(error?.localizedDescription ?? ""): \(attachment.header.seq)")
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
    
    func systemAgentDidReceiveRevokeDevice(reason: SystemAgentRevokeReason) {
        clearSampleAppAfterErrorHandling(sampleAppError: .deviceRevoked(reason: reason))
    }
}

// MARK: - SoundAgentDataSource

extension NuguCentralManager: SoundAgentDataSource {
    func soundAgentRequestUrl(beepName: SoundBeepName) -> URL? {
        let url: URL?
        switch beepName {
        case .responseFail:
            url = Bundle.main.url(forResource: "asrFail", withExtension: "wav")
        }
        return url
    }
}
