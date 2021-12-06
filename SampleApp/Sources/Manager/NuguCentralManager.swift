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
    
    lazy var themeController = NuguThemeController()
    
    private let notificationCenter = NotificationCenter.default
    private var systemAgentExceptionObserver: Any?
    private var systemAgentRevokeObserver: Any?
    private var dialogStateObserver: Any?
    
    lazy private(set) var client: NuguClient = {
        let nuguBuilder = NuguClient.Builder()

        // Set Last WakeUp Keyword
        // If you don't want to use saved wakeup-word, don't need to be implemented.
        // Because `aria` is set as a default keyword
        let wakeupDictionary = UserDefaults.Standard.wakeUpWordDictionary
        let wakeupRawValue = Int(wakeupDictionary["rawValue"] ?? "0") ?? 0
        let keywordItem = Keyword(
            rawValue: wakeupRawValue,
            description: wakeupDictionary["description"],
            netFilePath: Bundle.main.url(forResource: wakeupDictionary["netFileName"], withExtension: "raw")?.path,
            searchFilePath: Bundle.main.url(forResource: wakeupDictionary["searchFileName"], withExtension: "raw")?.path
        )

        if let keyword = keywordItem {
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
        addDialogStateObserver(client.dialogStateAggregator)
        
        // Initialize proper audio session for Nugu service usage
        // If you want to use your own audio session manager,
        // Set NuguClient's audio manager to nil and fill up NuguClientDelegate methods instead
        client.audioSessionManager?.updateAudioSession()
        
        return client
    }()
    
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
        
        if let dialogStateObserver = dialogStateObserver {
            notificationCenter.removeObserver(dialogStateObserver)
        }
    }
}

// MARK: - Internal (Enable / Disable)

extension NuguCentralManager {
    func refreshNugu() {
        guard UserDefaults.Standard.useNuguService else {
            NuguCentralManager.shared.disable()
            return
        }
        NuguCentralManager.shared.enable()
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

// MARK: - Internal (SpeechRecognizerAggregator)

extension NuguCentralManager {
    func startListening(initiator: ASRInitiator) {
        client.speechRecognizerAggregator.startListening(initiator: initiator)
    }
    
    func startListeningWithTrigger() {
        client.speechRecognizerAggregator.startListeningWithTrigger()
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

// MARK: - Internal (Chips Selection)

extension NuguCentralManager {
    func chipsDidSelect(selectedChips: NuguChipsButton.NuguChipsButtonType?) {
        guard let selectedChips = selectedChips,
            let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first else { return }
        
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.color = .black
        indicator.startAnimating()
        indicator.center = window.center
        indicator.startAnimating()
        window.addSubview(indicator)
        
        requestTextInput(text: selectedChips.text, token: selectedChips.token, requestType: .dialog) {
            DispatchQueue.main.async {
                indicator.removeFromSuperview()
            }
        }
    }
}

// MARK: - Private (Enable / Disable)

private extension NuguCentralManager {
    func enable() {
        log.debug("")
        startListeningWithTrigger()
        client.audioSessionManager?.enable()
        notificationCenter.post(name: .nuguServiceStateDidChangeNotification, object: nil, userInfo: ["isEnabled": true])
    }
    
    func disable() {
        log.debug("")
        stopListening()
        client.ttsAgent.stopTTS()
        client.audioPlayerAgent.stop()
        client.audioSessionManager?.disable()
        notificationCenter.post(name: .nuguServiceStateDidChangeNotification, object: nil, userInfo: ["isEnabled": false])
    }
}

// MARK: - Private (Observers)

private extension NuguCentralManager {
    func addSystemAgentObserver(_ object: SystemAgentProtocol) {
        systemAgentExceptionObserver = object.observe(NuguAgentNotification.System.Exception.self, queue: .main) { [weak self] (notification) in
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
                NuguToast.shared.showToast(message: SampleAppError.internalServiceException.errorDescription)
            }
        }

        systemAgentRevokeObserver = object.observe(NuguAgentNotification.System.RevokeDevice.self, queue: .main) { [weak self] (notification) in
            NuguToast.shared.showToast(message: notification.reason.rawValue)
            self?.clearSampleAppAfterErrorHandling()
        }
    }
    
    func addDialogStateObserver(_ object: DialogStateAggregator) {
        dialogStateObserver = object.observe(NuguClientNotification.DialogState.State.self, queue: nil) { [weak self] (notification) in
            self?.notificationCenter.post(name: .dialogStateDidChangeNotification, object: nil, userInfo: ["state": notification.state])
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

// MARK: - SoundAgentDataSource

extension NuguCentralManager: SoundAgentDataSource {
    func soundAgentRequestUrl(beepName: SoundBeepName, header: Downstream.Header) -> URL? {
        switch beepName {
        case .responseFail: return Bundle.main.url(forResource: "responsefail", withExtension: "wav")
        }
    }
}

// MARK: - NuguClientDelegate

extension NuguCentralManager: NuguClientDelegate {
    func nuguClientRequestAccessToken() -> String? {
        return UserDefaults.Standard.accessToken
    }

    func nuguClientDidChangeSpeechState(_ state: SpeechRecognizerAggregatorState) {
        if case .error(let error) = state, case ASRError.recognizeFailed = error {
            localTTSAgent.playLocalTTS(type: .deviceGatewayRequestUnacceptable)
        }
        notificationCenter.post(name: .speechStateDidChangeNotification, object: nil, userInfo: ["state": state])
    }
    
    func nuguClientDidSend(event: Event, error: Error?) {
        // Use some analytics SDK(or API) here.
        // Error: URLError or NetworkError or EventSenderError
        log.debug("\(error?.localizedDescription ?? ""): \(event.header.type)")
        guard let error = error else { return }
        handleNetworkError(error: error)
    }
}
