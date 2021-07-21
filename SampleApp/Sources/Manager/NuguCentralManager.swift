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
    
    private let notificationCenter = NotificationCenter.default
    private var systemAgentExceptionObserver: Any?
    private var systemAgentRevokeObserver: Any?
    
    lazy private(set) var client: NuguClient = {
        let nuguBuilder = NuguClient.Builder()

        // Set Last WakeUp Keyword
        // If you don't want to use saved wakeup-word, don't need to be implemented.
        // Because `aria` is set as a default keyword
        if let keyword = Keyword(rawValue: UserDefaults.Standard.wakeUpWord) {
            nuguBuilder.keywordDetector.keyword = keyword
        }
        
        // If you want to use built-in keyword detector, set this value as true
        nuguBuilder.speechRecognizerAggregator.useKeywordDetector = UserDefaults.Standard.useWakeUpDetector
        
        // Set DataSource for SoundAgent
        nuguBuilder.setDataSource(self)
        
        let client = nuguBuilder.build()
        client.delegate = self
        
        // Observers
        addSystemAgentObserver(client.systemAgent)
        
        // Initialize proper audio session for Nugu service usage
        // If you want to use your own audio session manager,
        // Set NuguClient's audio manager to nil and fill up NuguClientDelegate methods instead
        client.audioSessionManager?.updateAudioSession()
        
        return client
    }()
    
    lazy var themeController = NuguThemeController()
    
    lazy private(set) var localTTSAgent: LocalTTSAgent = LocalTTSAgent(focusManager: client.focusManager)
    
    lazy private(set) var oauthClient: NuguOAuthClient = {
        do {
            return try NuguOAuthClient(serviceName: Bundle.main.bundleIdentifier ?? "NuguSample")
        } catch {
            log.warning("OAuthClient has instantiated by using deviceUniqueId")
            return NuguOAuthClient(deviceUniqueId: "sample-device-unique-id")
        }
    }()
    
    private var authorizationInfo: AuthorizationInfo? {
        didSet {
            guard let authorizationInfo = authorizationInfo else { return }
            
            UserDefaults.Standard.accessToken = authorizationInfo.accessToken
            UserDefaults.Standard.refreshToken = authorizationInfo.refreshToken
        }
    }
    
    private init() {}
    
    deinit {
        if let systemAgentExceptionObserver = systemAgentExceptionObserver {
            notificationCenter.removeObserver(systemAgentExceptionObserver)
        }
        
        if let systemAgentRevokeObserver = systemAgentRevokeObserver {
            notificationCenter.removeObserver(systemAgentRevokeObserver)
        }
    }
}

// MARK: - Internal (Enable / Disable)

extension NuguCentralManager {
    func enable() {
        log.debug("")
        startListeningWithTrigger()
        client.audioSessionManager?.enable()
    }
    
    func disable() {
        log.debug("")
        stopListening()
        client.ttsAgent.stopTTS()
        client.audioPlayerAgent.stop()
        client.audioSessionManager?.disable()
    }
}

// MARK: - Internal (OAuth)

extension NuguCentralManager {
    func login(from viewController: UIViewController, completion: @escaping (Result<Void, SampleAppError>) -> Void) {
        guard let loginMethod = SampleApp.loginMethod else {
            completion(.failure(SampleAppError.nilValue(description: "loginMethod is nil")))
            return
        }
        
        switch loginMethod {
        case .tid:
            oauthClient.loginWithTid(parentViewController: viewController) { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    self?.authorizationInfo = authInfo
                    completion(.success(()))
                case .failure(let error):
                    let sampleAppError = SampleAppError.parseFromNuguLoginKitError(error: error)
                    completion(.failure(sampleAppError))
                }
            }
        case .anonymous:
            oauthClient.loginAnonymously { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    self?.authorizationInfo = authInfo
                    completion(.success(()))
                case .failure(let error):
                    let sampleAppError = SampleAppError.parseFromNuguLoginKitError(error: error)
                    completion(.failure(sampleAppError))
                }
            }
        }
    }
    
    func refreshToken(completion: @escaping (Result<Void, SampleAppError>) -> Void) {
        guard let loginMethod = SampleApp.loginMethod else {
            log.info("loginMethod is nil")
            completion(.failure(SampleAppError.nilValue(description: "loginMethod is nil")))
            return
        }
        
        switch loginMethod {
        case .tid:
            guard let refreshToken = UserDefaults.Standard.refreshToken else {
                completion(.failure(SampleAppError.nilValue(description: "RefreshToken is nil")))
                return
            }
            
            oauthClient.loginSilentlyWithTid(refreshToken: refreshToken) { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    self?.authorizationInfo = authInfo
                    completion(.success(()))
                case .failure(let error):
                    let sampleAppError = SampleAppError.parseFromNuguLoginKitError(error: error)
                    completion(.failure(sampleAppError))
                }
            }
        case .anonymous:
            oauthClient.loginAnonymously { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    self?.authorizationInfo = authInfo
                    completion(.success(()))
                case .failure(let error):
                    let sampleAppError = SampleAppError.parseFromNuguLoginKitError(error: error)
                    completion(.failure(sampleAppError))
                }
            }
        }
    }
    
    func revoke() {
        oauthClient.revoke { [weak self] (result) in
            switch result {
            case .success:
                self?.clearSampleApp()
            case .failure(let nuguLoginKitError):
                log.debug(nuguLoginKitError.localizedDescription)
            }
        }
    }
    
    func clearSampleApp() {
        authorizationInfo = nil
        popToRootViewController()
        disable()
        UserDefaults.Standard.clear()
        UserDefaults.Nugu.clear()
    }
    
    func getUserInfo(completion: @escaping (Result<NuguUserInfo, NuguLoginKitError>) -> Void) {
        oauthClient.getUserInfo { [weak self] (result) in
            switch result {
            case .failure(let nuguLoginKitError):
                let sampleAppError = SampleAppError.parseFromNuguLoginKitError(error: nuguLoginKitError)
                if case SampleAppError.loginUnauthorized = sampleAppError {
                    self?.clearSampleAppAfterErrorHandling()
                }
                completion(result)
            default: completion(result)
            }
        }
    }
    
    func showTidInfo(parentViewController: UIViewController, completion: @escaping () -> Void) {
        guard SampleApp.loginMethod == SampleApp.LoginMethod.tid else {
            log.error("loginMethod is not tid")
            completion()
            return
        }
        
        oauthClient.showTidInfo(parentViewController: parentViewController) { [weak self] (result) in
            if case .success(let authInfo) = result {
                self?.authorizationInfo = authInfo
            }
            completion()
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
    
    func clearSampleAppAfterErrorHandling() {
        DispatchQueue.main.async { [weak self] in
            self?.client.audioPlayerAgent.stop()
            self?.popToRootViewController()
            self?.localTTSAgent.playLocalTTS(type: .deviceGatewayAuthError, completion: { [weak self] in
                self?.authorizationInfo = nil
                self?.disable()
                UserDefaults.Standard.clear()
                UserDefaults.Nugu.clear()
            })
        }
    }
}

// MARK: - Private (NetworkError handling)
// TODO: - Should consider and decide for best way for handling network errors

private extension NuguCentralManager {
    func handleNetworkError(error: Error) {
        // Handle Nugu's predefined NetworkError        
        switch error {
        case NetworkError.authError:
            refreshToken { [weak self] result in
                switch result {
                case .success:
                    self?.enable()
                case .failure:
                    self?.clearSampleAppAfterErrorHandling()
                }
            }
        case NetworkError.timeout:
            localTTSAgent.playLocalTTS(type: .deviceGatewayTimeout)
        case is NetworkError:
            localTTSAgent.playLocalTTS(type: .deviceGatewayAuthServerError)
        case let urlError as URLError where [.networkConnectionLost, .notConnectedToInternet].contains(urlError.code):
            // In unreachable network status, play prepared local tts (deviceGatewayNetworkError)
            localTTSAgent.playLocalTTS(type: .deviceGatewayNetworkError)
        default:
            // Handle other URLErrors with your own way
            break
        }
    }
}

extension NuguCentralManager {
    func startListening(initiator: ASRInitiator) {
        client.speechRecognizerAggregator.startListening(initiator: initiator)
    }
    
    func startListeningWithTrigger() {
        client.speechRecognizerAggregator.startListeningWithTrigger { (result) in
            if case let .failure(error) = result {
                log.error("startListeningWithTrigger error: \(error)")
                return
            }
        }
    }
    
    func stopListening() {
        client.speechRecognizerAggregator.stopListening()
    }
}

// MARK: - Internal (Text)

extension NuguCentralManager {
    func requestTextInput(text: String, token: String? = nil, requestType: TextAgentRequestType, completion: (() -> Void)? = nil) {
        client.requestTextInput(text: text, token: token, requestType: requestType) { state in
            switch state {
            case .finished, .error:
                completion?()
            default: break
            }
        }
    }
}

// MARK: - NuguClientDelegate

extension NuguCentralManager: NuguClientDelegate {
    func nuguClientWillUseMic(requestingFocus: Bool) {
        // If you set AudioSessionManager to nil, You should implement this
        log.debug("nuguClientWillUseMic \(requestingFocus)")
    }
    
    func nuguClientDidRecognizeKeyword(initiator: ASRInitiator) {}
    
    func nuguClientDidChangeKeywordDetectorState(_ state: KeywordDetectorState) {}
    
    func nuguClientRequestAccessToken() -> String? {
        return UserDefaults.Standard.accessToken
    }
    
    func nuguClientWillRequireAudioSession() -> Bool {
        // If you set AudioSessionManager to nil, You should implement this
        // And return NUGU SDK can use the audio session or not.
        return false
    }
    
    func nuguClientDidReleaseAudioSession() {
        // If you set AudioSessionManager to nil, You should implement this
    }
    
    func nuguClientDidReceive(direcive: Downstream.Directive) {
        // Use some analytics SDK(or API) here.
        log.debug("\(direcive.header.type)")
    }
    
    func nuguClientDidReceive(attachment: Downstream.Attachment) {
        // Use some analytics SDK(or API) here.
        log.debug("\(attachment.header.type)")
    }
    
    func nuguClientWillSend(event: Upstream.Event) {
        // Use some analytics SDK(or API) here.
        log.debug("\(event.header.type)")
    }
    
    func nuguClientDidSend(event: Upstream.Event, error: Error?) {
        // Use some analytics SDK(or API) here.
        // Error: URLError or NetworkError or EventSenderError
        log.debug("\(error?.localizedDescription ?? ""): \(event.header.type)")
        guard let error = error else { return }
        handleNetworkError(error: error)
    }
    
    func nuguClientDidSend(attachment: Upstream.Attachment, error: Error?) {
        // Use some analytics SDK(or API) here.
        // Error: EventSenderError
        log.debug("\(error?.localizedDescription ?? ""): \(attachment.seq)")
    }
    
    func nuguClientServerInitiatedDirectiveRecevierStateDidChange(_ state: ServerSideEventReceiverState) {
        log.debug("nuguClientServerInitiatedDirectiveRecevierStateDidChange: \(state)")
    }
}

// MARK: - SoundAgentDataSource

extension NuguCentralManager: SoundAgentDataSource {
    func soundAgentRequestUrl(beepName: SoundBeepName, header: Downstream.Header) -> URL? {
        switch beepName {
        case .responseFail: return Bundle.main.url(forResource: "responsefail", withExtension: "wav")
        }
    }
}

// MARK: - Observer

private extension NuguCentralManager {
    func addSystemAgentObserver(_ object: SystemAgentProtocol) {
        systemAgentExceptionObserver = object.observe(NuguAgentNotification.System.Exception.self, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            
            switch notification.code {
            case .playRouterProcessingException:
                self.localTTSAgent.playLocalTTS(type: .deviceGatewayPlayRouterConnectionError)
            case .ttsSpeakingException:
                self.localTTSAgent.playLocalTTS(type: .deviceGatewayTTSConnectionError)
            case .unauthorizedRequestException:
                self.refreshToken { [weak self] result in
                    switch result {
                    case .success:
                        self?.enable()
                    case .failure:
                        self?.clearSampleAppAfterErrorHandling()
                    }
                }
            case .internalServiceException:
                DispatchQueue.main.async {
                    NuguToast.shared.showToast(message: SampleAppError.internalServiceException.errorDescription)
                }
            }
        }

        systemAgentRevokeObserver = object.observe(NuguAgentNotification.System.RevokeDevice.self, queue: nil) { [weak self] (notification) in
            DispatchQueue.main.async {
                NuguToast.shared.showToast(message: notification.reason.rawValue)
            }
            self?.clearSampleAppAfterErrorHandling()
        }
    }
}
